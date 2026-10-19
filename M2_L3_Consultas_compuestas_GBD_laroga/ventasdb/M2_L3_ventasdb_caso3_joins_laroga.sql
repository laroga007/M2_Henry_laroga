-- =========================================================
-- Caso 3: JOINs y operaciones de conjuntos (ventasdb)
-- =========================================================

-- 1) DETALLE DE PEDIDOS POR CLIENTE

-- Paso 1: visión completa de cada compra, uniendo las 4 tablas:
--   customers   → datos del cliente
--   orders      → número y fecha de la orden
--   order_items → qué productos y cuántas unidades
--   products    → nombre, categoría y precio
-- JOIN (INNER) trae solo lo que coincide en todas las tablas,
-- por eso Martín (sin órdenes) no aparece.
-- subtotal = cantidad × precio, con 2 decimales.
SELECT c.customer_id,
       c.full_name,
       o.order_id,
       o.order_date,
       p.product_id,
       p.product_name,
       p.category,
       p.price,
       oi.quantity,
       (oi.quantity * p.price)::numeric(12,2) AS subtotal
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
ORDER BY c.customer_id, o.order_date, o.order_id;

-- 2) ÍTEMS PROMEDIO POR CLIENTE

-- Paso 2: unidades promedio que compra cada cliente por orden.
-- per_order (WITH): suma las unidades de cada orden.
-- Consulta principal: promedia esas órdenes por cliente.
-- Se hace en dos pasos porque un AVG(quantity) directo promediaría
-- las líneas de la orden y no las órdenes completas.
WITH per_order AS (
  SELECT o.order_id,
         o.customer_id,
         SUM(oi.quantity) AS items_en_orden
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_id, o.customer_id
)
SELECT c.customer_id,
       c.full_name,
       AVG(items_en_orden)::numeric(10,2) AS items_promedio_por_orden
FROM per_order po
JOIN customers c ON c.customer_id = po.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY items_promedio_por_orden DESC;

-- 3) OPERACIONES DE CONJUNTOS

-- Paso 3: clientes que compraron Periféricos Y Pantallas.
-- clientes_perifericos (A) y clientes_pantallas (B) son dos WITH,
-- cada uno con la lista de clientes que compraron esa categoría.
-- DISTINCT evita repetir un cliente que compró varias veces.
-- INTERSECT se queda con los que están en las dos listas.
WITH clientes_perifericos AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Periféricos'
),
clientes_pantallas AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Pantallas'
)
SELECT customer_id FROM clientes_perifericos
INTERSECT
SELECT customer_id FROM clientes_pantallas;

-- Paso 4: clientes que compraron Periféricos O Pantallas (o ambos).
-- Mismos dos conjuntos que el paso 3.
-- UNION junta las dos listas y elimina los repetidos.
WITH clientes_perifericos AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Periféricos'
),
clientes_pantallas AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Pantallas'
)
SELECT customer_id FROM clientes_perifericos
UNION
SELECT customer_id FROM clientes_pantallas
ORDER BY customer_id;

-- Paso 5: ¿hay clientes que solo compran un tipo?
-- Decisión: el archivo original no responde esta pregunta; se agrega.
-- Lógica: (A UNION B) EXCEPT (A INTERSECT B)
--   UNION     → clientes que compraron algún tipo
--   INTERSECT → clientes que compraron los dos
--   EXCEPT    → resta: quedan los que compraron un solo tipo
WITH clientes_perifericos AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Periféricos'
),
clientes_pantallas AS (
  SELECT DISTINCT o.customer_id
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p     ON p.product_id = oi.product_id
  WHERE p.category = 'Pantallas'
)
SELECT customer_id FROM clientes_perifericos
UNION
SELECT customer_id FROM clientes_pantallas
EXCEPT
(SELECT customer_id FROM clientes_perifericos
 INTERSECT
 SELECT customer_id FROM clientes_pantallas);

