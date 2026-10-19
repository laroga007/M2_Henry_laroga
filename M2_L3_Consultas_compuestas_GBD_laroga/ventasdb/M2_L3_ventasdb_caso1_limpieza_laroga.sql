  -- =========================================================
-- Caso 1: Análisis temporal y limpieza de datos (ventasdb)
-- =========================================================

-- 1) LIMPIEZA DE EMAILS

-- Paso 1: vista previa (no modifica nada)
-- Muestra el email tal como está y cómo quedaría limpio:
-- LOWER pasa a minúsculas y TRIM quita espacios de los dos lados.
SELECT customer_id,
       email AS email_original,
       TRIM(LOWER(email)) AS email_limpio
FROM customers;

-- Paso 2: aplicar la limpieza (modifica la tabla)
-- UPDATE indica la tabla, SET la columna y su nuevo valor,
-- WHERE limita el cambio a las filas que tienen email.
-- Resultado: 3 filas actualizadas (ya estaban limpias, no cambió el contenido).
UPDATE customers
SET email = TRIM(LOWER(email))
WHERE email IS NOT NULL;

-- 2) SEPARAR NOMBRE Y APELLIDO

-- Paso 3: agregar las columnas first_name y last_name
-- IF NOT EXISTS evita el error si las columnas ya existen
-- (el archivo original hace lo mismo con un bloque DO $$).
ALTER TABLE customers ADD COLUMN IF NOT EXISTS first_name VARCHAR(60);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS last_name  VARCHAR(60);

SELECT * FROM customers;

-- Paso 4: completar first_name y last_name a partir de full_name
-- SPLIT_PART corta full_name por el espacio:
--   parte 1 = nombre, parte 2 = apellido.
-- NULLIF convierte en NULL las partes vacías
--   (por ejemplo, si alguien no tiene apellido cargado).
UPDATE customers
SET first_name = NULLIF(SPLIT_PART(full_name, ' ', 1), ''),
    last_name  = NULLIF(SPLIT_PART(full_name, ' ', 2), '')
WHERE full_name IS NOT NULL;

-- Verificación
SELECT customer_id, full_name, first_name, last_name
FROM customers;

-- Paso 5: chequeos de calidad (no modifican nada)

-- 5a) Nombres sin espacio: tienen una sola palabra,
--     así que les falta el nombre o el apellido.
--     POSITION devuelve 0 si no encuentra el espacio.
SELECT customer_id, full_name
FROM customers
WHERE POSITION(' ' IN full_name) = 0;

-- 5b) Emails con formato sospechoso:
--     un email válido tiene algo, una @, algo, un punto y algo.
--     NOT LIKE trae los que NO cumplen ese patrón.
SELECT customer_id, email
FROM customers
WHERE email NOT LIKE '%@%.%';

-- 3) CLIENTES NUEVOS DEL TRIMESTRE

-- Paso 6: clientes creados en el primer trimestre de 2024
-- BETWEEN incluye las dos fechas extremas.
-- Decisión: el archivo original usa abril-junio, pero en esa fecha
-- no hay clientes (da 0 filas); se usa enero-marzo, que tiene datos.
-- El original guarda las fechas en un WITH params; acá van directo en el WHERE.
SELECT customer_id,
       full_name,
       email,
       created_at
FROM customers
WHERE created_at BETWEEN '2024-01-01' AND '2024-03-31'
ORDER BY created_at;

-- 4) RESUMEN MENSUAL DE ÓRDENES

-- Paso 7: órdenes, unidades e ingresos por año y mes
-- Se unen 3 tablas con alias: orders (o), order_items (oi), products (p).
-- LEFT JOIN conserva las órdenes aunque no tengan ítems.
-- EXTRACT saca año y mes de la fecha; ::int lo deja como número entero.
-- COUNT(DISTINCT) cuenta cada orden una sola vez
--   (una orden con 2 ítems aparece en 2 filas del JOIN).
-- Ingresos = cantidad × precio, sumado.
SELECT EXTRACT(YEAR  FROM o.order_date)::int AS anio,
       EXTRACT(MONTH FROM o.order_date)::int AS mes,
       COUNT(DISTINCT o.order_id)            AS ordenes,
       SUM(oi.quantity)                      AS unidades,
       SUM(oi.quantity * p.price)            AS ingresos
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products p     ON p.product_id = oi.product_id
GROUP BY anio, mes
ORDER BY anio, mes;

-- 5) DETECCIÓN DE PICOS DE VENTAS

-- Paso 8: un mes es "pico" si sus ingresos superan
-- el promedio + 1 desvío estándar de todos los meses.
-- m: ingresos por mes (DATE_TRUNC agrupa cada fecha en su mes).
-- stats: promedio y desvío de esos ingresos mensuales.
-- CROSS JOIN pega el promedio y el desvío al lado de cada mes,
-- y CASE clasifica cada mes como 'pico' o 'normal'.
WITH m AS (
  SELECT DATE_TRUNC('month', o.order_date) AS periodo,
         SUM(oi.quantity * p.price) AS ingresos
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  GROUP BY 1
),
stats AS (
  SELECT AVG(ingresos)        AS avg_ing,
         STDDEV_POP(ingresos) AS sd_ing
  FROM m
)
SELECT m.periodo::date AS mes,
       m.ingresos,
       CASE WHEN m.ingresos > s.avg_ing + s.sd_ing
            THEN 'pico' ELSE 'normal' END AS clasificacion
FROM m CROSS JOIN stats s
ORDER BY mes;

-- 6) CLIENTES FRECUENTES POR ÉPOCA

-- Paso 9: cantidad de órdenes de cada cliente por año y trimestre
-- Decisión: el archivo original no incluía este pedido; se arma aparte.
-- "Época" = trimestre (EXTRACT con QUARTER devuelve 1 a 4).
-- Se ordena de más a menos órdenes dentro de cada trimestre.
SELECT EXTRACT(YEAR    FROM o.order_date)::int AS anio,
       EXTRACT(QUARTER FROM o.order_date)::int AS trimestre,
       c.full_name,
       COUNT(*) AS ordenes
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY anio, trimestre, c.full_name
ORDER BY anio, trimestre, ordenes DESC;

