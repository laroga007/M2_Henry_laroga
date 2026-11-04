"""
TravelNow - Consulta remota a Snowflake desde Python (extra mile, Lecture 7)

Se conecta a Snowflake con snowflake-connector-python y consulta la vista
VW_TOTAL_POR_DESTINO. La autenticación es por par de claves (key-pair): la clave
privada rsa_key.p8 queda en la computadora y no se publica (está en .gitignore);
la clave pública se registra en el usuario de Snowflake con ALTER USER.

Uso (desde la carpeta python, con el entorno virtual activo):
    export SNOWFLAKE_ACCOUNT='organizacion-cuenta'
    export SNOWFLAKE_USER='usuario'
    python consulta_travelnow.py
"""

import os

import snowflake.connector

# La cuenta y el usuario se leen de variables de entorno, para no publicarlos en GitHub
cuenta = os.getenv("SNOWFLAKE_ACCOUNT")
usuario = os.getenv("SNOWFLAKE_USER")

if not cuenta or not usuario:
    raise SystemExit(
        "Faltan datos de conexión. Antes de correr el script, escribí en la Terminal:\n"
        "    export SNOWFLAKE_ACCOUNT='organizacion-cuenta'\n"
        "    export SNOWFLAKE_USER='usuario'"
    )

# Conexión con la clave privada, sin contraseña
with snowflake.connector.connect(
    account=cuenta,
    user=usuario,
    authenticator="SNOWFLAKE_JWT",
    private_key_file="rsa_key.p8",
    role="SYSADMIN",
    warehouse="WH_TRAVELNOW",
    database="TRAVELNOW_DWH",
    schema="RESERVAS",
    enable_server_session_keep_alive_auto_detection=False,  # evita el aviso FutureWarning al conectar
) as conexion:
    with conexion.cursor() as cursor:
        cursor.execute("SELECT * FROM VW_TOTAL_POR_DESTINO ORDER BY TOTAL_USD DESC")

        # Nombres de las columnas, tal como los devuelve Snowflake
        columnas = [col[0] for col in cursor.description]
        print(" | ".join(columnas))

        for fila in cursor.fetchall():
            print(" | ".join(str(valor) for valor in fila))