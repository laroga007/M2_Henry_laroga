-- =========================================================
-- Lecture 6: plataforma de delivery - modelado dimensional avanzado
-- Base: delivery (PostgreSQL)
-- =========================================================

-- Paso 1: tablas para recibir los CSV
-- La columna año del CSV se llama anio, para no usar la ñ en PostgreSQL.
DROP TABLE IF EXISTS fact_pedidos, dim_clientes, dim_restaurantes, dim_fechas_pedidos;

CREATE TABLE dim_clientes (
    id_cliente    INT,
    ciudad        VARCHAR(50),
    tipo_usuario  VARCHAR(20),
    dispositivo   VARCHAR(20)
);

CREATE TABLE dim_restaurantes (
    id_restaurante  INT,
    nombre          VARCHAR(100),
    tipo_comida     VARCHAR(50),
    calificacion    DECIMAL(2,1)
);

CREATE TABLE dim_fechas_pedidos (
    id_fecha    INT,
    dia         INT,
    mes         INT,
    anio        INT,
    dia_semana  VARCHAR(10)
);

CREATE TABLE fact_pedidos (
    id_pedido       INT,
    id_cliente      INT,
    id_restaurante  INT,
    id_fecha        INT,
    monto_total     DECIMAL(10,2)
);

-- Verificación de la carga
SELECT 'dim_clientes' AS tabla, COUNT(*) AS filas FROM dim_clientes
UNION ALL SELECT 'dim_restaurantes',   COUNT(*) FROM dim_restaurantes
UNION ALL SELECT 'dim_fechas_pedidos', COUNT(*) FROM dim_fechas_pedidos
UNION ALL SELECT 'fact_pedidos',       COUNT(*) FROM fact_pedidos
UNION ALL SELECT 'fechas con anio',    COUNT(anio) FROM dim_fechas_pedidos;


-- Paso 3a: chequeos de calidad antes de crear las claves
-- Cuenta, en cada tabla, cuántos ID hay, cuántos distintos y cuántos nulos.
-- Si total = distintos y nulos = 0, la columna puede ser clave primaria.
SELECT 'fact_pedidos' AS tabla,
       COUNT(*) AS total, COUNT(DISTINCT id_pedido) AS distintos,
       COUNT(*) - COUNT(id_pedido) AS nulos
FROM fact_pedidos
UNION ALL
SELECT 'dim_clientes', COUNT(*), COUNT(DISTINCT id_cliente), COUNT(*) - COUNT(id_cliente)
FROM dim_clientes
UNION ALL
SELECT 'dim_restaurantes', COUNT(*), COUNT(DISTINCT id_restaurante), COUNT(*) - COUNT(id_restaurante)
FROM dim_restaurantes
UNION ALL
SELECT 'dim_fechas_pedidos', COUNT(*), COUNT(DISTINCT id_fecha), COUNT(*) - COUNT(id_fecha)
FROM dim_fechas_pedidos;

-- Paso 3b: claves e índices
-- Primero se borran las restricciones si ya existen, para poder volver a correr el paso.
-- Las foráneas se borran antes que las primarias, porque dependen de ellas.
ALTER TABLE fact_pedidos DROP CONSTRAINT IF EXISTS fk_fact_clientes;
ALTER TABLE fact_pedidos DROP CONSTRAINT IF EXISTS fk_fact_restaurantes;
ALTER TABLE fact_pedidos DROP CONSTRAINT IF EXISTS fk_fact_fechas;
ALTER TABLE fact_pedidos       DROP CONSTRAINT IF EXISTS fact_pedidos_pk;
ALTER TABLE dim_clientes       DROP CONSTRAINT IF EXISTS dim_clientes_pk;
ALTER TABLE dim_restaurantes   DROP CONSTRAINT IF EXISTS dim_restaurantes_pk;
ALTER TABLE dim_fechas_pedidos DROP CONSTRAINT IF EXISTS dim_fechas_pedidos_pk;

-- Claves primarias
ALTER TABLE fact_pedidos       ADD CONSTRAINT fact_pedidos_pk       PRIMARY KEY (id_pedido);
ALTER TABLE dim_clientes       ADD CONSTRAINT dim_clientes_pk       PRIMARY KEY (id_cliente);
ALTER TABLE dim_restaurantes   ADD CONSTRAINT dim_restaurantes_pk   PRIMARY KEY (id_restaurante);
ALTER TABLE dim_fechas_pedidos ADD CONSTRAINT dim_fechas_pedidos_pk PRIMARY KEY (id_fecha);

-- Claves foráneas: conectan la tabla de hechos con cada dimensión
ALTER TABLE fact_pedidos ADD CONSTRAINT fk_fact_clientes
    FOREIGN KEY (id_cliente) REFERENCES dim_clientes (id_cliente);
ALTER TABLE fact_pedidos ADD CONSTRAINT fk_fact_restaurantes
    FOREIGN KEY (id_restaurante) REFERENCES dim_restaurantes (id_restaurante);
ALTER TABLE fact_pedidos ADD CONSTRAINT fk_fact_fechas
    FOREIGN KEY (id_fecha) REFERENCES dim_fechas_pedidos (id_fecha);

-- Índices en las claves foráneas de la tabla de hechos (aceleran los JOIN)
CREATE INDEX IF NOT EXISTS idx_fact_pedidos_cliente     ON fact_pedidos (id_cliente);
CREATE INDEX IF NOT EXISTS idx_fact_pedidos_restaurante ON fact_pedidos (id_restaurante);
CREATE INDEX IF NOT EXISTS idx_fact_pedidos_fecha       ON fact_pedidos (id_fecha);

-- Índices en atributos por los que se suele filtrar o agrupar
CREATE INDEX IF NOT EXISTS idx_dim_clientes_ciudad       ON dim_clientes (ciudad);
CREATE INDEX IF NOT EXISTS idx_dim_clientes_tipo_usuario ON dim_clientes (tipo_usuario);
CREATE INDEX IF NOT EXISTS idx_dim_restaurantes_tipo     ON dim_restaurantes (tipo_comida);
CREATE INDEX IF NOT EXISTS idx_dim_fechas_anio_mes       ON dim_fechas_pedidos (anio, mes);

-- Paso 3c: verificar las claves creadas
-- Lista las restricciones de cada tabla: PRIMARY KEY o FOREIGN KEY.
SELECT table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
  AND constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
ORDER BY table_name, constraint_type DESC;

-- Ejemplo de análisis (star-join): total por ciudad y tipo de comida
SELECT dc.ciudad,
       dr.tipo_comida,
       SUM(fp.monto_total) AS total
FROM fact_pedidos fp
JOIN dim_clientes     dc ON dc.id_cliente     = fp.id_cliente
JOIN dim_restaurantes dr ON dr.id_restaurante = fp.id_restaurante
GROUP BY dc.ciudad, dr.tipo_comida
ORDER BY dc.ciudad, dr.tipo_comida;

-- Paso 4a: hecho transaccional
-- Cada fila de fact_pedidos es un pedido: un evento que ocurrió una vez.
-- Ejemplo: todos los pedidos del cliente 301.
SELECT id_pedido, id_cliente, id_restaurante, id_fecha, monto_total
FROM fact_pedidos
WHERE id_cliente = 301
ORDER BY id_fecha;

-- Paso 4b: total acumulado por cliente con una función de ventana
-- No es un "hecho acumulativo" en sentido estricto: es un total corrido
-- calculado sobre la tabla transaccional.
-- id_pedido desempata si un cliente tiene dos pedidos el mismo día.
SELECT id_cliente,
       id_fecha,
       monto_total,
       SUM(monto_total) OVER (PARTITION BY id_cliente
                              ORDER BY id_fecha, id_pedido) AS acumulado
FROM fact_pedidos
ORDER BY id_cliente, id_fecha;


-- Paso 5a: métricas aditivas
-- 1) Total gastado por cliente
SELECT id_cliente,
       SUM(monto_total) AS total_gastado
FROM fact_pedidos
GROUP BY id_cliente
ORDER BY total_gastado DESC;

-- 2) Ingreso por ciudad
SELECT c.ciudad,
       SUM(f.monto_total) AS total_ingresos
FROM fact_pedidos f
JOIN dim_clientes c ON c.id_cliente = f.id_cliente
GROUP BY c.ciudad
ORDER BY total_ingresos DESC;

-- 3) Ingreso por día de la semana
-- Se agrupa por dia_semana (el nombre del día).
-- MIN(id_fecha) ordena los días en orden cronológico.
SELECT d.dia_semana,
       SUM(f.monto_total) AS total_ingresos
FROM fact_pedidos f
JOIN dim_fechas_pedidos d ON d.id_fecha = f.id_fecha
GROUP BY d.dia_semana
ORDER BY MIN(d.id_fecha);


-- Paso 5b: métricas derivadas
-- 1) Ticket promedio por cliente = total gastado / cantidad de pedidos
SELECT id_cliente,
       COUNT(*) AS pedidos,
       ROUND(SUM(monto_total) / COUNT(*), 2) AS ticket_promedio
FROM fact_pedidos
GROUP BY id_cliente
ORDER BY ticket_promedio DESC;

-- 2) Monto promedio por tipo de comida
SELECT r.tipo_comida,
       COUNT(*) AS pedidos,
       ROUND(AVG(f.monto_total), 2) AS monto_promedio
FROM fact_pedidos f
JOIN dim_restaurantes r ON r.id_restaurante = f.id_restaurante
GROUP BY r.tipo_comida
ORDER BY monto_promedio DESC;

-- 3) Pedidos por restaurante, y cuántos pedidos hace cada cliente en él
SELECT r.nombre,
       COUNT(*) AS pedidos,
       COUNT(DISTINCT f.id_cliente) AS clientes,
       ROUND(COUNT(*)::numeric / COUNT(DISTINCT f.id_cliente), 2) AS pedidos_por_cliente
FROM fact_pedidos f
JOIN dim_restaurantes r ON r.id_restaurante = f.id_restaurante
GROUP BY r.nombre
ORDER BY pedidos DESC;

-- 4) Ratio de pedidos de clientes recurrentes sobre el total
-- FILTER cuenta solo las filas que cumplen la condición.
SELECT COUNT(*) AS pedidos_totales,
       COUNT(*) FILTER (WHERE c.tipo_usuario = 'Recurrente') AS pedidos_recurrentes,
       ROUND(100.0 * COUNT(*) FILTER (WHERE c.tipo_usuario = 'Recurrente') / COUNT(*), 1) AS pct_recurrentes
FROM fact_pedidos f
JOIN dim_clientes c ON c.id_cliente = f.id_cliente;

-- Paso 6b: SCD Tipo 2 - tabla de historial de clientes
-- Cada cambio de un cliente agrega una fila nueva (una "versión").
-- id_history es la clave sustituta: identifica cada versión, no al cliente.
DROP TABLE IF EXISTS dim_clientes_history;

CREATE TABLE dim_clientes_history (
    id_history             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente             INT         NOT NULL REFERENCES dim_clientes (id_cliente),
    ciudad                 VARCHAR(50),
    tipo_usuario           VARCHAR(20),
    dispositivo            VARCHAR(20),
    fecha_inicio_vigencia  DATE        NOT NULL,
    fecha_fin_vigencia     DATE,       -- NULL mientras la versión está vigente
    activo                 BOOLEAN     NOT NULL DEFAULT TRUE
);

-- Estado inicial: una versión por cliente, vigente desde el 1/1/2023,
-- antes del primer pedido (1/7/2023).
INSERT INTO dim_clientes_history (id_cliente, ciudad, tipo_usuario, dispositivo, fecha_inicio_vigencia)
SELECT id_cliente, ciudad, tipo_usuario, dispositivo, DATE '2023-01-01'
FROM dim_clientes;

-- Verificación: 7 filas, todas activas y sin fecha de fin
SELECT * FROM dim_clientes_history ORDER BY id_cliente;


-- Paso 6c: registrar cambios (SCD Tipo 2) y actualizar el estado actual

-- Cliente 301: se muda de Buenos Aires a Córdoba el 1/9/2023
-- 1) Cerrar la versión vigente: termina el día anterior al cambio
UPDATE dim_clientes_history
SET fecha_fin_vigencia = DATE '2023-08-31', activo = FALSE
WHERE id_cliente = 301 AND activo;

-- 2) Agregar la versión nueva, copiando los datos que no cambian
INSERT INTO dim_clientes_history (id_cliente, ciudad, tipo_usuario, dispositivo, fecha_inicio_vigencia)
SELECT id_cliente, 'Córdoba', tipo_usuario, dispositivo, DATE '2023-09-01'
FROM dim_clientes_history
WHERE id_cliente = 301 AND fecha_fin_vigencia = DATE '2023-08-31';

-- Cliente 305: pasa de Nuevo a Recurrente el 1/9/2023
UPDATE dim_clientes_history
SET fecha_fin_vigencia = DATE '2023-08-31', activo = FALSE
WHERE id_cliente = 305 AND activo;

INSERT INTO dim_clientes_history (id_cliente, ciudad, tipo_usuario, dispositivo, fecha_inicio_vigencia)
SELECT id_cliente, ciudad, 'Recurrente', dispositivo, DATE '2023-09-01'
FROM dim_clientes_history
WHERE id_cliente = 305 AND fecha_fin_vigencia = DATE '2023-08-31';

-- Estado actual en dim_clientes
-- Ciudad: se sobrescribe (el historial queda en dim_clientes_history)
UPDATE dim_clientes SET ciudad = 'Córdoba' WHERE id_cliente = 301;

-- Tipo de usuario: SCD Tipo 3, se guarda el valor anterior en otra columna.
-- La condición tipo_usuario = 'Nuevo' evita pisar el valor anterior si se vuelve a ejecutar.
ALTER TABLE dim_clientes ADD COLUMN IF NOT EXISTS tipo_usuario_anterior VARCHAR(20);

UPDATE dim_clientes
SET tipo_usuario_anterior = tipo_usuario,
    tipo_usuario = 'Recurrente'
WHERE id_cliente = 305 AND tipo_usuario = 'Nuevo';

-- Verificación
SELECT * FROM dim_clientes_history
WHERE id_cliente IN (301, 305)
ORDER BY id_cliente, fecha_inicio_vigencia;

SELECT * FROM dim_clientes ORDER BY id_cliente;

-- Paso 6d: cruzar los pedidos con la versión vigente del cliente
-- id_fecha es un número (20230701): TO_DATE lo convierte en fecha.
-- La versión vigente es la que tiene la fecha del pedido entre su inicio y su fin.
-- COALESCE: si la versión sigue vigente (fin NULL), se toma una fecha muy lejana.

-- 1) Pedidos de los clientes que cambiaron: estado actual vs. estado en el pedido
SELECT f.id_pedido,
       f.id_cliente,
       TO_DATE(f.id_fecha::text, 'YYYYMMDD') AS fecha_pedido,
       c.ciudad       AS ciudad_actual,
       h.ciudad       AS ciudad_en_el_pedido,
       c.tipo_usuario AS tipo_actual,
       h.tipo_usuario AS tipo_en_el_pedido
FROM fact_pedidos f
JOIN dim_clientes c ON c.id_cliente = f.id_cliente
JOIN dim_clientes_history h
  ON h.id_cliente = f.id_cliente
 AND TO_DATE(f.id_fecha::text, 'YYYYMMDD')
     BETWEEN h.fecha_inicio_vigencia AND COALESCE(h.fecha_fin_vigencia, DATE '9999-12-31')
WHERE f.id_cliente IN (301, 305)
ORDER BY f.id_pedido;

-- 2) Ingreso por ciudad: según el historial vs. según el estado actual
WITH historial AS (
    SELECT h.ciudad, SUM(f.monto_total) AS total
    FROM fact_pedidos f
    JOIN dim_clientes_history h
      ON h.id_cliente = f.id_cliente
     AND TO_DATE(f.id_fecha::text, 'YYYYMMDD')
         BETWEEN h.fecha_inicio_vigencia AND COALESCE(h.fecha_fin_vigencia, DATE '9999-12-31')
    GROUP BY h.ciudad
),
actual AS (
    SELECT c.ciudad, SUM(f.monto_total) AS total
    FROM fact_pedidos f
    JOIN dim_clientes c ON c.id_cliente = f.id_cliente
    GROUP BY c.ciudad
)
SELECT COALESCE(h.ciudad, a.ciudad) AS ciudad,
       h.total AS segun_historial,
       a.total AS segun_estado_actual
FROM historial h
FULL JOIN actual a ON a.ciudad = h.ciudad
ORDER BY ciudad;

-- Paso 6e: SCD Tipo 1 - el restaurante 403 cambia de nombre
-- Se sobrescribe el valor: no queda registro del nombre anterior.
UPDATE dim_restaurantes
SET nombre = 'Burger the King'
WHERE id_restaurante = 403;

-- Impacto: también los pedidos anteriores al cambio muestran el nombre nuevo
SELECT f.id_pedido, f.id_fecha, r.nombre, f.monto_total
FROM fact_pedidos f
JOIN dim_restaurantes r ON r.id_restaurante = f.id_restaurante
WHERE f.id_restaurante = 403
ORDER BY f.id_pedido;


-- Paso 7a: tabla de hechos agregada - pedidos por día y restaurante
-- Granularidad: una fila por restaurante y día (no por pedido).
DROP TABLE IF EXISTS fact_pedidos_diarios;

CREATE TABLE fact_pedidos_diarios AS
SELECT id_restaurante,
       id_fecha,
       COUNT(*)                        AS cantidad_pedidos,
       SUM(monto_total)                AS monto_total_diario,
       ROUND(AVG(monto_total), 2)      AS ticket_promedio_diario
FROM fact_pedidos
GROUP BY id_restaurante, id_fecha;

ALTER TABLE fact_pedidos_diarios
    ADD PRIMARY KEY (id_restaurante, id_fecha);

-- Verificación: los totales tienen que coincidir con fact_pedidos
SELECT COUNT(*)                AS filas,
       SUM(cantidad_pedidos)   AS pedidos,
       SUM(monto_total_diario) AS monto
FROM fact_pedidos_diarios;

-- Snapshot de restaurantes: el estado de cada restaurante en una fecha.
-- Una sola tabla para todos los snapshots: cada fecha agrega una fila por restaurante.
DROP TABLE IF EXISTS snapshot_restaurantes;

CREATE TABLE snapshot_restaurantes (
    fecha_snapshot  DATE         NOT NULL,
    id_restaurante  INT          NOT NULL REFERENCES dim_restaurantes (id_restaurante),
    nombre          VARCHAR(100),
    tipo_comida     VARCHAR(50),
    calificacion    DECIMAL(2,1),
    PRIMARY KEY (fecha_snapshot, id_restaurante)
);

-- Se toma el snapshot de hoy
INSERT INTO snapshot_restaurantes
SELECT CURRENT_DATE, id_restaurante, nombre, tipo_comida, calificacion
FROM dim_restaurantes;

SELECT * FROM snapshot_restaurantes ORDER BY id_restaurante;


-- Paso 7b: mini-dimensión de perfil del cliente (atributos volátiles)
-- Se borra primero la columna de la tabla de hechos, porque depende de la mini-dimensión.
ALTER TABLE fact_pedidos DROP COLUMN IF EXISTS id_perfil;
DROP TABLE IF EXISTS dim_perfil_cliente;

-- Una fila por combinación de dispositivo y estado de campaña (no por cliente)
CREATE TABLE dim_perfil_cliente (
    id_perfil       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    dispositivo     VARCHAR(20) NOT NULL,
    estado_campana  VARCHAR(20) NOT NULL,
    UNIQUE (dispositivo, estado_campana)
);

-- Se cargan todas las combinaciones: 3 dispositivos x 3 estados = 9 perfiles.
-- El dataset no informa campañas, por eso existe el estado 'Sin dato'.
INSERT INTO dim_perfil_cliente (dispositivo, estado_campana)
SELECT d.dispositivo, e.estado
FROM (SELECT DISTINCT dispositivo FROM dim_clientes) d
CROSS JOIN (VALUES ('Activa'), ('Inactiva'), ('Sin dato')) AS e(estado)
ORDER BY d.dispositivo, e.estado;

-- La tabla de hechos apunta a la mini-dimensión: cada pedido guarda su perfil
ALTER TABLE fact_pedidos
    ADD COLUMN id_perfil INT REFERENCES dim_perfil_cliente (id_perfil);

-- Asignación: el dispositivo sale de dim_clientes; la campaña, 'Sin dato'
UPDATE fact_pedidos f
SET id_perfil = p.id_perfil
FROM dim_clientes c
JOIN dim_perfil_cliente p
  ON p.dispositivo = c.dispositivo AND p.estado_campana = 'Sin dato'
WHERE c.id_cliente = f.id_cliente;

-- Uso: pedidos e ingresos por dispositivo, a través de la mini-dimensión
SELECT p.dispositivo,
       COUNT(*)           AS pedidos,
       SUM(f.monto_total) AS monto
FROM fact_pedidos f
JOIN dim_perfil_cliente p ON p.id_perfil = f.id_perfil
GROUP BY p.dispositivo
ORDER BY pedidos DESC;


-- Paso 7c: dimensión degenerada - id_pedido
-- No tiene tabla propia: se usa directamente desde fact_pedidos para rastrear un pedido.
-- Ejemplo: toda la información del pedido 7.
SELECT f.id_pedido,
       d.dia_semana,
       c.ciudad,
       r.nombre      AS restaurante,
       p.dispositivo,
       f.monto_total
FROM fact_pedidos f
JOIN dim_fechas_pedidos d ON d.id_fecha       = f.id_fecha
JOIN dim_clientes       c ON c.id_cliente     = f.id_cliente
JOIN dim_restaurantes   r ON r.id_restaurante = f.id_restaurante
JOIN dim_perfil_cliente p ON p.id_perfil      = f.id_perfil
WHERE f.id_pedido = 7;


-- Paso 8a: índices existentes en la tabla de hechos
-- pg_indexes es una vista del sistema con todos los índices de la base.
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'fact_pedidos'
ORDER BY indexname;

-- Paso 8b: tabla de hechos particionada por fecha
-- En PostgreSQL una tabla tiene que crearse particionada desde el inicio:
-- por eso se crea una nueva y se copian los datos.
-- CASCADE borra también sus particiones.
DROP TABLE IF EXISTS fact_pedidos_particionada CASCADE;

CREATE TABLE fact_pedidos_particionada (
    id_pedido       INT,
    id_cliente      INT,
    id_restaurante  INT,
    fecha           DATE,
    monto_total     DECIMAL(10,2)
) PARTITION BY RANGE (fecha);

-- Partición 2023. El límite superior no se incluye:
-- TO '2024-01-01' abarca hasta el 31/12/2023 inclusive.
CREATE TABLE fact_pedidos_2023
    PARTITION OF fact_pedidos_particionada
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

-- Partición por defecto: recibe las fechas que no entran en ninguna otra.
-- Sin ella, cargar un pedido de otro año daría error.
CREATE TABLE fact_pedidos_default
    PARTITION OF fact_pedidos_particionada DEFAULT;

-- Copiar los pedidos, convirtiendo id_fecha (20230701) en fecha
INSERT INTO fact_pedidos_particionada (id_pedido, id_cliente, id_restaurante, fecha, monto_total)
SELECT id_pedido, id_cliente, id_restaurante,
       TO_DATE(id_fecha::text, 'YYYYMMDD'),
       monto_total
FROM fact_pedidos;

-- Verificación: en qué partición quedó cada pedido
-- tableoid::regclass muestra el nombre de la tabla física de cada fila.
SELECT tableoid::regclass AS particion,
       COUNT(*)           AS pedidos,
       SUM(monto_total)   AS monto
FROM fact_pedidos_particionada
GROUP BY tableoid;

-- Plan de ejecución: con un filtro por fecha, solo se lee la partición de 2023
EXPLAIN
SELECT * FROM fact_pedidos_particionada
WHERE fecha BETWEEN DATE '2023-07-01' AND DATE '2023-07-31';

-- Paso 8c: vista materializada - ranking de restaurantes por monto
DROP MATERIALIZED VIEW IF EXISTS top_restaurantes;

CREATE MATERIALIZED VIEW top_restaurantes AS
SELECT r.id_restaurante,
       r.nombre,
       SUM(f.monto_total) AS monto_total_acumulado,
       COUNT(*)           AS cantidad_pedidos
FROM fact_pedidos f
JOIN dim_restaurantes r ON r.id_restaurante = f.id_restaurante
GROUP BY r.id_restaurante, r.nombre;

-- Índice único: permite consultarla rápido por restaurante
-- y además habilita REFRESH ... CONCURRENTLY.
CREATE UNIQUE INDEX idx_top_restaurantes_rest ON top_restaurantes (id_restaurante);

-- Uso: el orden se pide al consultar, no al crearla
SELECT * FROM top_restaurantes ORDER BY monto_total_acumulado DESC;

-- Después de cargar pedidos nuevos, se refresca.
-- CONCURRENTLY deja seguir consultándola mientras se actualiza.
REFRESH MATERIALIZED VIEW CONCURRENTLY top_restaurantes;
