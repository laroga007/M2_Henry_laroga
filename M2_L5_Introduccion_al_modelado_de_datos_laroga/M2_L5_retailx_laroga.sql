-- =========================================================
-- Lecture 5: RetailX - modelo dimensional
-- Base: retailx (PostgreSQL)
-- =========================================================

-- Paso 1: tabla de staging (copia fiel del CSV)
-- Los nombres van sin tildes para no usar comillas en PostgreSQL
-- (el CSV trae categoría, región y método_pago).
-- DROP primero: permite volver a correr el script desde cero.
DROP TABLE IF EXISTS stg_ventas;

CREATE TABLE stg_ventas (
    id_venta            INT,
    fecha_venta         DATE,
    hora                TIME,
    cliente_id          INT,
    tipo_cliente        VARCHAR(20),
    producto_id         VARCHAR(10),
    producto_nombre     VARCHAR(100),
    categoria           VARCHAR(50),
    cantidad            INT,
    precio_unitario     DECIMAL(10,2),
    descuento_aplicado  INT,
    total_venta         DECIMAL(12,2),
    canal_venta         VARCHAR(20),
    pais                VARCHAR(50),
    region              VARCHAR(20),
    sucursal            VARCHAR(20),
    metodo_pago         VARCHAR(20)
);

SELECT COUNT(*) AS filas,
       COUNT(categoria) AS con_categoria,
       COUNT(region) AS con_region,
       COUNT(metodo_pago) AS con_metodo_pago
FROM stg_ventas;

-- 3a) ¿Cada cliente tiene un solo tipo?
SELECT cliente_id,
       COUNT(*) AS compras,
       STRING_AGG(DISTINCT tipo_cliente, ', ') AS tipos,
       STRING_AGG(DISTINCT pais, ', ') AS paises
FROM stg_ventas
GROUP BY cliente_id
HAVING COUNT(DISTINCT tipo_cliente) > 1;

-- 3b) ¿Cada sucursal está en un solo lugar?
SELECT sucursal,
       COUNT(*) AS ventas,
       STRING_AGG(DISTINCT pais, ', ') AS paises,
       STRING_AGG(DISTINCT region, ', ') AS regiones
FROM stg_ventas
GROUP BY sucursal
ORDER BY sucursal;

-- Paso 4: modelo estrella
-- Se borra primero la tabla de hechos, porque depende de las dimensiones.
DROP TABLE IF EXISTS f_ventas;
DROP TABLE IF EXISTS d_producto;
DROP TABLE IF EXISTS d_cliente;
DROP TABLE IF EXISTS d_ubicacion;
DROP TABLE IF EXISTS d_tiempo;

-- Dimensión producto: cada código tiene un solo nombre, categoría y precio.
CREATE TABLE d_producto (
    producto_id      VARCHAR(10)   PRIMARY KEY,
    producto_nombre  VARCHAR(100)  NOT NULL,
    categoria        VARCHAR(50)   NOT NULL,
    precio_lista     DECIMAL(10,2) NOT NULL
);

-- Dimensión cliente: solo el identificador.
-- tipo_cliente y país no van acá porque cambian según la venta.
CREATE TABLE d_cliente (
    cliente_id  INT PRIMARY KEY
);

-- Dimensión ubicación: la sucursal sola no identifica un lugar,
-- por eso cada combinación país + región + sucursal tiene su propia clave.
CREATE TABLE d_ubicacion (
    ubicacion_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pais          VARCHAR(50) NOT NULL,
    region        VARCHAR(20) NOT NULL,
    sucursal      VARCHAR(20) NOT NULL,
    UNIQUE (pais, region, sucursal)
);

-- Dimensión tiempo: una fila por fecha, con sus partes ya calculadas.
CREATE TABLE d_tiempo (
    fecha       DATE        PRIMARY KEY,
    anio        INT         NOT NULL,
    mes         INT         NOT NULL,
    dia         INT         NOT NULL,
    dia_semana  VARCHAR(10) NOT NULL
);

-- Tabla de hechos: una fila por venta.
CREATE TABLE f_ventas (
    id_venta            INT           PRIMARY KEY,
    fecha               DATE          NOT NULL REFERENCES d_tiempo(fecha),
    hora                TIME          NOT NULL,
    cliente_id          INT           NOT NULL REFERENCES d_cliente(cliente_id),
    producto_id         VARCHAR(10)   NOT NULL REFERENCES d_producto(producto_id),
    ubicacion_id        INT           NOT NULL REFERENCES d_ubicacion(ubicacion_id),
    tipo_cliente        VARCHAR(20)   NOT NULL,
    canal_venta         VARCHAR(20)   NOT NULL,
    metodo_pago         VARCHAR(20)   NOT NULL,
    cantidad            INT           NOT NULL,
    precio_unitario     DECIMAL(10,2) NOT NULL,
    descuento_aplicado  INT           NOT NULL,
    total_venta         DECIMAL(12,2) NOT NULL
);

-- Paso 5: carga del modelo (ETL desde stg_ventas)

-- Vacía las tablas del modelo antes de cargar: permite volver a correr el paso 5.
-- RESTART IDENTITY reinicia el contador de ubicacion_id en 1.
TRUNCATE f_ventas, d_producto, d_cliente, d_ubicacion, d_tiempo RESTART IDENTITY;

-- d_producto: un registro por producto (DISTINCT elimina repetidos)
INSERT INTO d_producto (producto_id, producto_nombre, categoria, precio_lista)
SELECT DISTINCT producto_id, producto_nombre, categoria, precio_unitario
FROM stg_ventas;

-- d_cliente: un registro por cliente
INSERT INTO d_cliente (cliente_id)
SELECT DISTINCT cliente_id
FROM stg_ventas;

-- d_ubicacion: un registro por combinación de país, región y sucursal.
-- ubicacion_id no se escribe: lo genera PostgreSQL.
INSERT INTO d_ubicacion (pais, region, sucursal)
SELECT DISTINCT pais, region, sucursal
FROM stg_ventas;

-- d_tiempo: un registro por fecha, con sus partes calculadas.
-- ISODOW numera los días de 1 (lunes) a 7 (domingo).
INSERT INTO d_tiempo (fecha, anio, mes, dia, dia_semana)
SELECT DISTINCT fecha_venta,
       EXTRACT(YEAR  FROM fecha_venta)::int,
       EXTRACT(MONTH FROM fecha_venta)::int,
       EXTRACT(DAY   FROM fecha_venta)::int,
       CASE EXTRACT(ISODOW FROM fecha_venta)::int
            WHEN 1 THEN 'Lunes'   WHEN 2 THEN 'Martes'  WHEN 3 THEN 'Miércoles'
            WHEN 4 THEN 'Jueves'  WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sábado'
            ELSE 'Domingo'
       END
FROM stg_ventas;

-- f_ventas: una fila por venta.
-- El JOIN con d_ubicacion convierte país + región + sucursal en su ubicacion_id.
INSERT INTO f_ventas (id_venta, fecha, hora, cliente_id, producto_id, ubicacion_id,
                      tipo_cliente, canal_venta, metodo_pago,
                      cantidad, precio_unitario, descuento_aplicado, total_venta)
SELECT s.id_venta, s.fecha_venta, s.hora, s.cliente_id, s.producto_id, u.ubicacion_id,
       s.tipo_cliente, s.canal_venta, s.metodo_pago,
       s.cantidad, s.precio_unitario, s.descuento_aplicado, s.total_venta
FROM stg_ventas s
JOIN d_ubicacion u
  ON u.pais = s.pais AND u.region = s.region AND u.sucursal = s.sucursal;

-- Verificación: filas por tabla y total vendido en staging y en el modelo
SELECT 'd_producto' AS tabla, COUNT(*) AS filas FROM d_producto
UNION ALL SELECT 'd_cliente',   COUNT(*) FROM d_cliente
UNION ALL SELECT 'd_ubicacion', COUNT(*) FROM d_ubicacion
UNION ALL SELECT 'd_tiempo',    COUNT(*) FROM d_tiempo
UNION ALL SELECT 'f_ventas',    COUNT(*) FROM f_ventas;

SELECT (SELECT SUM(total_venta) FROM stg_ventas) AS total_staging,
       (SELECT SUM(total_venta) FROM f_ventas)   AS total_modelo;

-- Paso 6a: venta neta y descuento resignado por país y categoría
-- Sin costo en el dataset no se puede calcular margen;
-- se usan la venta neta y el descuento resignado como aproximación.
SELECT u.pais,
       p.categoria,
       SUM(f.total_venta) AS venta_neta,
       SUM(f.cantidad * f.precio_unitario - f.total_venta) AS descuento_resignado
FROM f_ventas f
JOIN d_producto  p ON p.producto_id  = f.producto_id
JOIN d_ubicacion u ON u.ubicacion_id = f.ubicacion_id
GROUP BY u.pais, p.categoria
ORDER BY u.pais, venta_neta DESC;

-- Paso 6b: ventas por franja horaria
-- Franjas: Mañana 8-11, Mediodía 12-14, Tarde 15-17, Noche 18-20.
-- El número delante del nombre ordena las franjas en el orden del día.
SELECT CASE
         WHEN EXTRACT(HOUR FROM f.hora) < 12 THEN '1 Mañana'
         WHEN EXTRACT(HOUR FROM f.hora) < 15 THEN '2 Mediodía'
         WHEN EXTRACT(HOUR FROM f.hora) < 18 THEN '3 Tarde'
         ELSE '4 Noche'
       END AS franja,
       COUNT(*)                      AS ventas,
       SUM(f.cantidad)               AS unidades,
       SUM(f.total_venta)            AS venta_neta,
       ROUND(AVG(f.total_venta), 2)  AS ticket_promedio
FROM f_ventas f
GROUP BY franja
ORDER BY franja;

-- Paso 6c: nuevos vs recurrentes, por canal de venta
-- tipo_cliente se toma de f_ventas: es el tipo en el momento de cada compra.
SELECT f.tipo_cliente,
       f.canal_venta,
       COUNT(*)                      AS ventas,
       SUM(f.cantidad)               AS unidades,
       SUM(f.total_venta)            AS venta_neta,
       ROUND(AVG(f.total_venta), 2)  AS ticket_promedio
FROM f_ventas f
GROUP BY f.tipo_cliente, f.canal_venta
ORDER BY f.tipo_cliente, f.canal_venta;