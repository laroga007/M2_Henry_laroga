-- =========================================================
-- Lecture 7 - Homework: TravelNow - Data Warehouse en Snowflake
-- Se ejecuta en Snowsight. Los CSV de data/ se suben a los stages en el paso 2.
-- =========================================================

-- Paso 1: warehouse, base de datos y esquema
USE ROLE SYSADMIN;

-- Warehouse XSMALL, con auto-suspend a los 5 minutos y auto-resume
CREATE WAREHOUSE IF NOT EXISTS WH_TRAVELNOW
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND        = 300
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS TRAVELNOW_DWH COMMENT = 'Data Warehouse de TravelNow';
CREATE SCHEMA   IF NOT EXISTS TRAVELNOW_DWH.RESERVAS;

-- Formato de archivo: el mismo que en RetailX
USE SCHEMA TRAVELNOW_DWH.RESERVAS;

CREATE OR REPLACE FILE FORMAT FF_CSV
  TYPE                         = CSV
  FIELD_DELIMITER              = ','
  SKIP_HEADER                  = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE                   = TRUE
  EMPTY_FIELD_AS_NULL          = TRUE
  ENCODING                     = 'UTF8';

-- Stages internos. IF NOT EXISTS: no se recrean ni se pierden los archivos.
CREATE STAGE IF NOT EXISTS STG_RESERVAS        FILE_FORMAT = FF_CSV;
CREATE STAGE IF NOT EXISTS STG_CLIENTES_TRAVEL FILE_FORMAT = FF_CSV;
CREATE STAGE IF NOT EXISTS STG_DESTINOS        FILE_FORMAT = FF_CSV;

-- Verificación
SHOW STAGES IN SCHEMA TRAVELNOW_DWH.RESERVAS;

-- Paso 2: subir cada CSV a su stage desde Catalog (no es SQL) y verificar
LIST @STG_DESTINOS;

-- Corrección: se había subido reservas.csv al stage de destinos
REMOVE @STG_DESTINOS/reservas.csv;

LIST @STG_DESTINOS;
LIST @STG_RESERVAS;
LIST @STG_CLIENTES_TRAVEL;

-- Paso 3: tablas y carga desde los stages
-- Las columnas van en el mismo orden que los CSV: COPY INTO carga por posición.
USE WAREHOUSE WH_TRAVELNOW;
USE SCHEMA TRAVELNOW_DWH.RESERVAS;

CREATE OR REPLACE TABLE CLIENTES_TRAVEL (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  STRING,
    EMAIL          STRING,
    COUNTRY        STRING
);

CREATE OR REPLACE TABLE DESTINOS (
    DESTINATION  STRING,
    REGION       STRING,
    CLIMATE      STRING
);

CREATE OR REPLACE TABLE RESERVAS (
    BOOKING_ID      NUMBER,
    CUSTOMER_ID     NUMBER,
    DESTINATION     STRING,
    DEPARTURE_DATE  DATE,
    NIGHTS          NUMBER,
    PRICE_USD       NUMBER(10,2)
);

-- Carga. FORCE = TRUE porque las tablas se recrean vacías con CREATE OR REPLACE.
COPY INTO CLIENTES_TRAVEL FROM @STG_CLIENTES_TRAVEL FORCE = TRUE;
COPY INTO DESTINOS        FROM @STG_DESTINOS        FORCE = TRUE;
COPY INTO RESERVAS        FROM @STG_RESERVAS        FORCE = TRUE;

-- Verificación
SELECT 'CLIENTES_TRAVEL' AS tabla, COUNT(*) AS filas FROM CLIENTES_TRAVEL
UNION ALL SELECT 'DESTINOS', COUNT(*) FROM DESTINOS
UNION ALL SELECT 'RESERVAS', COUNT(*) FROM RESERVAS;

-- Paso 4: consulta de validación
-- Total de reservas (suma de price_usd) por país de origen del cliente
SELECT c.COUNTRY      AS pais_origen,
       COUNT(*)       AS reservas,
       SUM(r.NIGHTS)  AS noches,
       SUM(r.PRICE_USD) AS total_usd
FROM RESERVAS r
JOIN CLIENTES_TRAVEL c ON c.CUSTOMER_ID = r.CUSTOMER_ID
GROUP BY c.COUNTRY
ORDER BY total_usd DESC;

-- Paso 5 (extra mile): vista con el total gastado por destino
-- Une cada reserva con su destino para sumar también región y clima.
CREATE OR REPLACE VIEW VW_TOTAL_POR_DESTINO AS
SELECT d.DESTINATION        AS destino,
       d.REGION             AS region,
       d.CLIMATE            AS clima,
       COUNT(r.BOOKING_ID)  AS reservas,
       SUM(r.NIGHTS)        AS noches,
       SUM(r.PRICE_USD)     AS total_usd
FROM DESTINOS d
LEFT JOIN RESERVAS r ON r.DESTINATION = d.DESTINATION
GROUP BY d.DESTINATION, d.REGION, d.CLIMATE;

-- Uso
SELECT * FROM VW_TOTAL_POR_DESTINO ORDER BY total_usd DESC;
