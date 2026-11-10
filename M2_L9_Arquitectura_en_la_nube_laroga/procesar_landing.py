"""
GreenSense: procesamiento de la landing zone (maqueta local de la arquitectura en AWS)

Cumple el papel de la función Lambda de la arquitectura:
  1. Lee los CSV de data/landing (equivale al bucket S3 de la landing zone).
  2. Valida cada fila y separa las rechazadas (calidad de datos).
  3. Carga las filas válidas en PostgreSQL, base greensense (equivale a RDS).
  4. Actualiza el estado actual de cada estación (equivale a DynamoDB).
  5. Muestra alertas cuando el PM2.5 supera el umbral (equivale a CloudWatch).
  6. Registra el linaje de cada carga: archivo, tabla, filas leídas, cargadas y rechazadas.

Uso (con el contenedor de PostgreSQL encendido y el entorno virtual activo):
    export PGPASSWORD='contraseña_de_postgres'
    python procesar_landing.py

Se puede volver a ejecutar: las filas que ya están cargadas no se duplican.
"""

import csv
import os

import psycopg

LANDING = "data/landing"
BASE = "greensense"
UMBRAL_PM25 = 15.0  # µg/m³. Guía de la OMS (2021) para la media de 24 h; se usa como referencia.

# Conexión: usuario, contraseña, host y puerto se leen de variables de entorno,
# para que no queden escritos en el código.
CONEXION = {
    "host": os.getenv("PGHOST", "localhost"),
    "port": os.getenv("PGPORT", "5432"),
    "user": os.getenv("PGUSER", "postgres"),
    "password": os.getenv("PGPASSWORD"),
}

ESQUEMA = """
CREATE TABLE IF NOT EXISTS estaciones (
    station_id        INT PRIMARY KEY,
    location          VARCHAR(100) NOT NULL,
    latitude          NUMERIC(9,6),
    longitude         NUMERIC(9,6),
    installation_date DATE
);

CREATE TABLE IF NOT EXISTS mediciones (
    measurement_id INT PRIMARY KEY,
    station_id     INT NOT NULL REFERENCES estaciones (station_id),
    timestamp      TIMESTAMP NOT NULL,
    temperature_c  NUMERIC(5,2),
    humidity_pct   NUMERIC(5,2),
    pm2_5          NUMERIC(6,2)   -- partículas finas, en µg/m³
);

CREATE TABLE IF NOT EXISTS eventos (
    event_id   INT PRIMARY KEY,
    station_id INT NOT NULL REFERENCES estaciones (station_id),
    timestamp  TIMESTAMP NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    severity   VARCHAR(20)
);

-- Estado actual de cada estación: una fila por estación, que se sobrescribe en cada carga
CREATE TABLE IF NOT EXISTS estado_estaciones (
    station_id      INT PRIMARY KEY REFERENCES estaciones (station_id),
    ultima_medicion TIMESTAMP,
    pm2_5           NUMERIC(6,2),
    ultimo_evento   VARCHAR(50),
    estado          VARCHAR(20),
    actualizado_en  TIMESTAMP
);

-- Linaje: de qué archivo salió cada carga y qué pasó con sus filas
CREATE TABLE IF NOT EXISTS linaje_cargas (
    carga_id         SERIAL PRIMARY KEY,
    archivo          VARCHAR(200) NOT NULL,
    tabla_destino    VARCHAR(50)  NOT NULL,
    filas_leidas     INT,
    filas_cargadas   INT,
    filas_rechazadas INT,
    cargado_en       TIMESTAMP DEFAULT now()
);
"""


def crear_base_si_no_existe():
    """Crea la base greensense la primera vez (equivale a crear la instancia de RDS)."""
    with psycopg.connect(dbname="postgres", autocommit=True, **CONEXION) as con:
        existe = con.execute("SELECT 1 FROM pg_database WHERE datname = %s", (BASE,)).fetchone()
        if not existe:
            con.execute(f"CREATE DATABASE {BASE}")
            print(f"Base '{BASE}' creada.")


def validar(fila, tabla, estaciones_validas):
    """Devuelve la fila convertida a sus tipos, o el motivo por el que se rechaza."""
    try:
        if tabla == "estaciones":
            return (int(fila["station_id"]), fila["location"].strip(),
                    float(fila["latitude"]), float(fila["longitude"]),
                    fila["installation_date"]), None

        estacion = int(fila["station_id"])
        if estacion not in estaciones_validas:
            return None, f"estación {estacion} inexistente"

        if tabla == "mediciones":
            humedad, pm = float(fila["humidity_pct"]), float(fila["pm2_5"])
            if not 0 <= humedad <= 100:
                return None, f"humedad fuera de rango ({humedad})"
            if pm < 0:
                return None, f"PM2.5 negativo ({pm})"
            return (int(fila["measurement_id"]), estacion, fila["timestamp"],
                    float(fila["temperature_c"]), humedad, pm), None

        if tabla == "eventos":
            return (int(fila["event_id"]), estacion, fila["timestamp"],
                    fila["event_type"].strip(), fila["severity"].strip()), None
    except (ValueError, KeyError) as error:
        return None, f"dato inválido ({error})"


INSERTS = {
    "estaciones": "INSERT INTO estaciones VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
    "mediciones": "INSERT INTO mediciones VALUES (%s, %s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
    "eventos":    "INSERT INTO eventos VALUES (%s, %s, %s, %s, %s) ON CONFLICT DO NOTHING",
}


def cargar(con, tabla):
    """Lee el CSV de la landing zone, valida, carga y registra el linaje."""
    archivo = os.path.join(LANDING, f"{tabla}.csv")
    estaciones_validas = {fila[0] for fila in con.execute("SELECT station_id FROM estaciones")}
    leidas = cargadas = rechazadas = 0

    with open(archivo, newline="", encoding="utf-8") as f:
        for fila in csv.DictReader(f):
            leidas += 1
            valores, motivo = validar(fila, tabla, estaciones_validas)
            if motivo:
                rechazadas += 1
                print(f"  ✗ {tabla}: fila {leidas} rechazada: {motivo}")
                continue
            cargadas += con.execute(INSERTS[tabla], valores).rowcount  # 0 si ya estaba cargada

    con.execute(
        "INSERT INTO linaje_cargas (archivo, tabla_destino, filas_leidas, filas_cargadas, filas_rechazadas) "
        "VALUES (%s, %s, %s, %s, %s)",
        (archivo, tabla, leidas, cargadas, rechazadas),
    )
    print(f"  {tabla}: {leidas} leídas, {cargadas} nuevas, {rechazadas} rechazadas")


def actualizar_estado(con):
    """Última medición y último evento de cada estación, y su estado."""
    con.execute(
        """
        INSERT INTO estado_estaciones
        SELECT e.station_id, m.timestamp, m.pm2_5, ev.event_type,
               CASE
                   WHEN ev.event_type = 'SENSOR_DESCONECTADO'
                        AND ev.timestamp >= COALESCE(m.timestamp, ev.timestamp) THEN 'DESCONECTADA'
                   WHEN m.pm2_5 > %(umbral)s THEN 'ALERTA_PM25'
                   WHEN m.timestamp IS NULL THEN 'SIN_DATOS'
                   ELSE 'OK'
               END,
               now()
        FROM estaciones e
        LEFT JOIN LATERAL (SELECT timestamp, pm2_5 FROM mediciones
                           WHERE station_id = e.station_id
                           ORDER BY timestamp DESC LIMIT 1) m ON true
        LEFT JOIN LATERAL (SELECT timestamp, event_type FROM eventos
                           WHERE station_id = e.station_id
                           ORDER BY timestamp DESC LIMIT 1) ev ON true
        ON CONFLICT (station_id) DO UPDATE SET
            ultima_medicion = EXCLUDED.ultima_medicion,
            pm2_5           = EXCLUDED.pm2_5,
            ultimo_evento   = EXCLUDED.ultimo_evento,
            estado          = EXCLUDED.estado,
            actualizado_en  = EXCLUDED.actualizado_en
        """,
        {"umbral": UMBRAL_PM25},
    )


def mostrar_alertas(con):
    """Mediciones con PM2.5 sobre el umbral y eventos críticos."""
    print(f"\nAlertas (PM2.5 > {UMBRAL_PM25} µg/m³ y eventos de severidad Alta o Media)")
    for loc, ts, pm in con.execute(
        "SELECT s.location, m.timestamp, m.pm2_5 FROM mediciones m "
        "JOIN estaciones s USING (station_id) WHERE m.pm2_5 > %s ORDER BY m.timestamp",
        (UMBRAL_PM25,),
    ):
        print(f"  🚨 {loc} {ts:%H:%M}: PM2.5 = {pm} µg/m³")
    for loc, ts, tipo, sev in con.execute(
        "SELECT s.location, e.timestamp, e.event_type, e.severity FROM eventos e "
        "JOIN estaciones s USING (station_id) WHERE e.severity IN ('Alta', 'Media') ORDER BY e.timestamp"
    ):
        print(f"  🚨 {loc} {ts:%H:%M}: {tipo} (severidad {sev})")

    print("\nEstado actual de las estaciones")
    for loc, ts, pm, estado in con.execute(
        "SELECT s.location, x.ultima_medicion, x.pm2_5, x.estado FROM estado_estaciones x "
        "JOIN estaciones s USING (station_id) ORDER BY x.station_id"
    ):
        print(f"  {loc:<13} última medición {ts:%H:%M}  PM2.5 {pm:>5}  →  {estado}")


def main():
    if not CONEXION["password"]:
        raise SystemExit("Falta la contraseña. Antes de correr el script, escribí en la Terminal:\n"
                         "    export PGPASSWORD='contraseña_de_postgres'")
    crear_base_si_no_existe()
    with psycopg.connect(dbname=BASE, **CONEXION) as con:
        con.execute(ESQUEMA)
        print("Carga desde la landing zone")
        for tabla in ("estaciones", "mediciones", "eventos"):  # estaciones primero: las otras dependen de ella
            cargar(con, tabla)
        actualizar_estado(con)
        mostrar_alertas(con)
    # Al salir del bloque "with" se confirma la transacción (commit).


if __name__ == "__main__":
    main()
