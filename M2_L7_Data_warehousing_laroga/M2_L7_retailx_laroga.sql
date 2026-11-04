-- =========================================================
-- Lecture 7: RetailX - Data Warehouse en Snowflake
-- Se ejecuta en Snowsight. Los CSV de data/ se suben a los stages en el paso 5.
-- =========================================================

-- Paso 2: warehouses
-- SYSADMIN es el rol pensado para crear objetos (warehouses, bases, tablas).
-- ACCOUNTADMIN se reserva para administrar la cuenta.
USE ROLE SYSADMIN;

-- Warehouse para cargar datos
CREATE WAREHOUSE IF NOT EXISTS WH_CARGA
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND        = 300      -- segundos: se apaga a los 5 minutos sin uso
  AUTO_RESUME         = TRUE     -- se enciende solo al ejecutar una consulta
  INITIALLY_SUSPENDED = TRUE;    -- se crea apagado: no consume hasta que se use

-- Warehouse para consultas de análisis
CREATE WAREHOUSE IF NOT EXISTS WH_ANALISIS
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND        = 300
  AUTO_RESUME         = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- Verificación
SHOW WAREHOUSES;

-- Paso 3: base de datos y esquemas
-- RAW: datos crudos, tal como llegan de los CSV.
-- DW: datos listos para analizar.
CREATE DATABASE IF NOT EXISTS RETAILX_DWH COMMENT = 'Data Warehouse de RetailX';
CREATE SCHEMA   IF NOT EXISTS RETAILX_DWH.RAW;
CREATE SCHEMA   IF NOT EXISTS RETAILX_DWH.DW;

-- Verificación
SHOW SCHEMAS IN DATABASE RETAILX_DWH;

-- Paso 4: formato de archivo y stages (en el esquema RAW)
USE SCHEMA RETAILX_DWH.RAW;

-- Cómo leer los CSV
CREATE OR REPLACE FILE FORMAT FF_CSV
  TYPE                         = CSV
  FIELD_DELIMITER              = ','
  SKIP_HEADER                  = 1        -- la primera fila tiene los nombres de las columnas
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'      -- por si algún texto viene entre comillas
  TRIM_SPACE                   = TRUE     -- quita espacios sobrantes
  EMPTY_FIELD_AS_NULL          = TRUE     -- un campo vacío se carga como NULL
  ENCODING                     = 'UTF8';  -- respeta tildes y ñ

-- Un stage interno por archivo.
-- IF NOT EXISTS (y no OR REPLACE): si el script se vuelve a ejecutar,
-- el stage no se recrea y no se pierden los archivos ya subidos.
CREATE STAGE IF NOT EXISTS STG_CLIENTES  FILE_FORMAT = FF_CSV;
CREATE STAGE IF NOT EXISTS STG_PRODUCTOS FILE_FORMAT = FF_CSV;
CREATE STAGE IF NOT EXISTS STG_VENTAS    FILE_FORMAT = FF_CSV;

-- Verificación
SHOW STAGES IN SCHEMA RETAILX_DWH.RAW;

-- Paso 5: subir cada CSV a su stage desde Catalog (no es SQL) y verificar
LIST @STG_CLIENTES;
LIST @STG_PRODUCTOS;
LIST @STG_VENTAS;

-- Paso 6: tablas en RAW y carga desde los stages
-- Las columnas van en el mismo orden que los CSV: COPY INTO carga por posición.
USE WAREHOUSE WH_CARGA;
USE SCHEMA RETAILX_DWH.RAW;

CREATE OR REPLACE TABLE CLIENTES (
    CUSTOMER_ID    NUMBER,
    CUSTOMER_NAME  STRING,
    EMAIL          STRING,
    REGION         STRING
);

CREATE OR REPLACE TABLE PRODUCTOS (
    PRODUCT_ID    NUMBER,
    PRODUCT_NAME  STRING,
    CATEGORY      STRING
);

CREATE OR REPLACE TABLE VENTAS (
    ORDER_ID     NUMBER,
    CUSTOMER_ID  NUMBER,
    PRODUCT_ID   NUMBER,
    ORDER_DATE   DATE,
    QUANTITY     NUMBER,
    UNIT_PRICE   NUMBER(10,2)
);

-- Carga: cada tabla desde su stage.
-- FORCE = TRUE vuelve a cargar los archivos aunque figuren como ya cargados.
-- Se usa porque las tablas se recrean vacías con CREATE OR REPLACE.
COPY INTO CLIENTES  FROM @STG_CLIENTES  FORCE = TRUE;
COPY INTO PRODUCTOS FROM @STG_PRODUCTOS FORCE = TRUE;
COPY INTO VENTAS    FROM @STG_VENTAS    FORCE = TRUE;

-- Verificación
SELECT 'CLIENTES' AS tabla, COUNT(*) AS filas FROM CLIENTES
UNION ALL SELECT 'PRODUCTOS', COUNT(*) FROM PRODUCTOS
UNION ALL SELECT 'VENTAS',    COUNT(*) FROM VENTAS;

-- Paso 7: capa DW (datos listos para analizar)
-- Se crean a partir de RAW. En VENTAS se agrega el total de cada línea.
USE WAREHOUSE WH_CARGA;
USE SCHEMA RETAILX_DWH.DW;

CREATE OR REPLACE TABLE CLIENTES AS
SELECT CUSTOMER_ID, CUSTOMER_NAME, EMAIL, REGION
FROM RETAILX_DWH.RAW.CLIENTES;

CREATE OR REPLACE TABLE PRODUCTOS AS
SELECT PRODUCT_ID, PRODUCT_NAME, CATEGORY
FROM RETAILX_DWH.RAW.PRODUCTOS;

CREATE OR REPLACE TABLE VENTAS AS
SELECT ORDER_ID, CUSTOMER_ID, PRODUCT_ID, ORDER_DATE,
       QUANTITY, UNIT_PRICE,
       QUANTITY * UNIT_PRICE AS TOTAL_LINEA
FROM RETAILX_DWH.RAW.VENTAS;

-- Verificación: total vendido
SELECT COUNT(*) AS ventas, SUM(TOTAL_LINEA) AS total_vendido
FROM RETAILX_DWH.DW.VENTAS;

-- Paso 8: política de enmascaramiento del email
-- Los roles administradores ven el email completo; el resto, solo el dominio.
USE ROLE SYSADMIN;
USE SCHEMA RETAILX_DWH.DW;

CREATE OR REPLACE MASKING POLICY MASK_EMAIL AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN', 'SECURITYADMIN') THEN val
    ELSE CONCAT('***', SUBSTR(val, POSITION('@' IN val)))
  END;

-- Aplicar la política a la columna EMAIL
ALTER TABLE RETAILX_DWH.DW.CLIENTES
  MODIFY COLUMN EMAIL SET MASKING POLICY MASK_EMAIL;

-- Prueba 1: con SYSADMIN, el email aparece enmascarado
SELECT CUSTOMER_ID, CUSTOMER_NAME, EMAIL FROM RETAILX_DWH.DW.CLIENTES;

-- Prueba 2: con ACCOUNTADMIN, el email aparece completo
USE ROLE ACCOUNTADMIN;
SELECT CUSTOMER_ID, CUSTOMER_NAME, EMAIL FROM RETAILX_DWH.DW.CLIENTES;

-- Se vuelve al rol de trabajo
USE ROLE SYSADMIN;

-- Paso 9: rol de analista y usuario de ejemplo
-- SECURITYADMIN es el rol pensado para administrar roles, usuarios y permisos.
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS ANALYST_RETAILX;

-- Permisos: usar el warehouse de análisis y leer el esquema DW.
-- No se da acceso a RAW ni permisos de escritura.
GRANT USAGE  ON WAREHOUSE WH_ANALISIS                     TO ROLE ANALYST_RETAILX;
GRANT USAGE  ON DATABASE  RETAILX_DWH                     TO ROLE ANALYST_RETAILX;
GRANT USAGE  ON SCHEMA    RETAILX_DWH.DW                  TO ROLE ANALYST_RETAILX;
GRANT SELECT ON ALL TABLES    IN SCHEMA RETAILX_DWH.DW    TO ROLE ANALYST_RETAILX;
GRANT SELECT ON FUTURE TABLES IN SCHEMA RETAILX_DWH.DW    TO ROLE ANALYST_RETAILX;

-- Usuario de ejemplo. La contraseña es provisoria: se pide cambiarla al ingresar
-- y el usuario se elimina al final de la práctica.
-- En la versión publicada, la contraseña se reemplaza por un marcador.
CREATE USER IF NOT EXISTS RETAILX_ANALYST
  PASSWORD             = '<CONTRASENA_PROVISORIA>'
  DEFAULT_ROLE         = ANALYST_RETAILX
  DEFAULT_WAREHOUSE    = WH_ANALISIS
  MUST_CHANGE_PASSWORD = TRUE;

GRANT ROLE ANALYST_RETAILX TO USER RETAILX_ANALYST;

-- Verificación: qué permisos tiene el rol
SHOW GRANTS TO ROLE ANALYST_RETAILX;

-- Paso 10: análisis por región y por categoría
USE ROLE SYSADMIN;
USE WAREHOUSE WH_ANALISIS;
USE SCHEMA RETAILX_DWH.DW;

-- 10a) Ventas por región del cliente
SELECT c.REGION,
       COUNT(*)           AS ventas,
       SUM(v.QUANTITY)    AS unidades,
       SUM(v.TOTAL_LINEA) AS total
FROM VENTAS v
JOIN CLIENTES c ON c.CUSTOMER_ID = v.CUSTOMER_ID
GROUP BY c.REGION
ORDER BY total DESC;

-- 10b) Ventas por categoría de producto
SELECT p.CATEGORY,
       COUNT(*)           AS ventas,
       SUM(v.QUANTITY)    AS unidades,
       SUM(v.TOTAL_LINEA) AS total
FROM VENTAS v
JOIN PRODUCTOS p ON p.PRODUCT_ID = v.PRODUCT_ID
GROUP BY p.CATEGORY
ORDER BY total DESC;
