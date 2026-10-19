-- =========================================================
-- Caso 2: Ventas por producto y ranking de clientes (ventasdb)
-- =========================================================

-- 1) VENTAS POR PRODUCTO

-- Paso 1: por cada producto, total vendido, veces vendido,
-- promedio por orden e ingresos.
-- SUM(quantity)            → total de unidades vendidas
-- COUNT(DISTINCT order_id) → en cuántas órdenes se vendió
-- AVG(quantity)            → unidades promedio por orden
-- ::numeric(10,2)          → redondea a 2 decimales
-- Se ordena de mayor a menor ingreso.
SELECT p.product_id,
       p.product_name,
       p.category,
       SUM(oi.quantity)                           AS unidades_totales,
       COUNT(DISTINCT oi.order_id)                AS ordenes_distintas,
       AVG(oi.quantity)::numeric(10,2)            AS unidades_prom_por_orden,
       SUM(oi.quantity * p.price)::numeric(12,2)  AS ingresos_totales
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY ingresos_totales DESC;

-- 2) FILTRAR PRODUCTOS DESTACADOS

-- Paso 2: productos con más de 3 unidades vendidas
-- O con ingresos mayores a 200.
-- HAVING filtra los grupos después del GROUP BY
-- (WHERE no sirve acá porque SUM se calcula recién al agrupar).
-- OR: alcanza con que se cumpla una de las dos condiciones.
SELECT p.product_id,
       p.product_name,
       SUM(oi.quantity)           AS unidades_totales,
       SUM(oi.quantity * p.price) AS ingresos
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
HAVING SUM(oi.quantity) > 3
    OR SUM(oi.quantity * p.price) > 200
ORDER BY ingresos DESC;

-- 3) RANKING DE CLIENTES

-- Paso 3: ¿quién hizo más compras?
-- COUNT(*) cuenta las órdenes de cada cliente.
-- Se une con customers para mostrar el nombre.
-- Orden: más órdenes primero; si empatan, por customer_id.
-- LIMIT 10 muestra como máximo los 10 primeros.
SELECT o.customer_id,
       c.full_name,
       COUNT(*) AS cant_ordenes
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY o.customer_id, c.full_name
ORDER BY cant_ordenes DESC, o.customer_id
LIMIT 10;

-- Paso 4: ¿quién compró más productos?
-- Acá se usa SUM(quantity) y no COUNT(*):
-- no interesa cuántas órdenes hizo, sino cuántas unidades compró en total
-- (una orden puede tener varias unidades).
-- Se unen 3 tablas: orders → order_items (cantidades) → customers (nombre).
SELECT o.customer_id,
       c.full_name,
       SUM(oi.quantity) AS unidades_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN customers c    ON c.customer_id = o.customer_id
GROUP BY o.customer_id, c.full_name
ORDER BY unidades_total DESC
LIMIT 10;