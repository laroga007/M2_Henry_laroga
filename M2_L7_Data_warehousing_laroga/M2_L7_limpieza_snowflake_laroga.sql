-- =========================================================
-- Lecture 7: limpieza de la cuenta de Snowflake
-- Elimina todo lo creado en RetailX y en el homework TravelNow,
-- para que no queden objetos ni warehouses consumiendo créditos.
-- Ejecutar al terminar los dos trabajos, con Run All.
-- =========================================================

USE ROLE ACCOUNTADMIN;

-- Bases de datos. Al eliminar la base se eliminan también sus esquemas,
-- tablas, vistas, stages (con los archivos subidos), formatos de archivo
-- y la política de enmascaramiento.
DROP DATABASE IF EXISTS RETAILX_DWH;
DROP DATABASE IF EXISTS TRAVELNOW_DWH;

-- Warehouses
DROP WAREHOUSE IF EXISTS WH_CARGA;
DROP WAREHOUSE IF EXISTS WH_ANALISIS;
DROP WAREHOUSE IF EXISTS WH_TRAVELNOW;

-- Usuario y rol de analista de RetailX
DROP USER IF EXISTS RETAILX_ANALYST;
DROP ROLE IF EXISTS ANALYST_RETAILX;

-- Clave pública registrada para la conexión desde Python.
-- El nombre del usuario se toma de la sesión; las comillas dobles respetan
-- las minúsculas del nombre.
SET usuario_actual = '"' || CURRENT_USER() || '"';
ALTER USER IDENTIFIER($usuario_actual) UNSET RSA_PUBLIC_KEY;

-- Verificación: las cuatro consultas tienen que devolver 0 filas
SHOW DATABASES  LIKE '%_DWH';
SHOW WAREHOUSES LIKE 'WH_%';
SHOW ROLES      LIKE 'ANALYST_RETAILX';
SHOW USERS      LIKE 'RETAILX_ANALYST';

-- Verificación de la clave: HAS_KEYPAIR tiene que decir false
DESC USER IDENTIFIER($usuario_actual);
