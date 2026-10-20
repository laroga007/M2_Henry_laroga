-- =========================================================
-- Homework Lecture 3: VentasDB
-- =========================================================
-- Estado de la base al empezar: incluye la orden 5 de prueba
-- (caso 4, cliente 2, sin ítems), el trigger, los índices y las vistas.

-- ---------------------------------------------------------
-- 1) MANIPULACIÓN DE DATOS TEMPORALES Y TEXTUALES
-- ---------------------------------------------------------

-- Paso 1: fecha de la última orden de cada cliente.
-- MAX(order_date) toma la fecha más reciente.
-- LEFT JOIN para incluir también a los clientes sin órdenes (quedan en NULL).
-- dias_sin_comprar = hoy - última orden (la "R" de Recency en RFM).
-- Decisión: se usa LEFT JOIN y no JOIN para no perder clientes sin compras,
-- que también son información para el negocio.
SELECT c.customer_id,
       c.full_name,
       MAX(o.order_date)                AS ultima_orden,
       CURRENT_DATE - MAX(o.order_date) AS dias_sin_comprar
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY c.customer_id;

-- Decisión: se elimina la orden 5, creada en el caso 4 solo para probar
-- el trigger (sin ítems, fecha de prueba). Distorsiona recency y frequency.
-- Se conserva su registro en audit_logs: la auditoría guarda lo que pasó.
DELETE FROM orders WHERE order_id = 5;

-- Verificación: vuelve a correr el paso 1.
-- Lucía tiene que quedar con su última orden real: 2024-04-03.

-- Paso 2: first_name y last_name desde full_name.
-- Ya realizado en el caso 1 (pasos 3 y 4): se agregaron las columnas
-- con ALTER TABLE y se completaron con SPLIT_PART.
-- Acá solo se verifica que estén cargadas.
-- Limitación detectada: SPLIT_PART corta por el primer espacio.
-- Con nombres compuestos ("María José López") el apellido quedaría mal.
-- En esta base no hay casos así; con más datos habría que revisarlo.
SELECT customer_id, full_name, first_name, last_name
FROM customers
ORDER BY customer_id;

-- Paso 3: outliers textuales en emails.
-- Se considera mal registrado un email que:
--   - no tiene @ (NOT LIKE '%@%')
--   - tiene espacios en cualquier lugar (LIKE '% %')
--   - está vacío (IS NULL)
-- Decisión: los NULL también cuentan como mal registrados,
-- porque un cliente sin email no se puede contactar.

-- 3a) Detectar: clasificación de cada email con CASE
SELECT customer_id,
       email,
       CASE
         WHEN email IS NULL         THEN 'vacío'
         WHEN email NOT LIKE '%@%'  THEN 'sin @'
         WHEN email LIKE '% %'      THEN 'con espacios'
         ELSE 'ok'
       END AS estado_email
FROM customers
ORDER BY customer_id;

-- 3b) Cuantificar: cuántos clientes están mal registrados
SELECT COUNT(*) AS emails_mal_registrados
FROM customers
WHERE email IS NULL
   OR email NOT LIKE '%@%'
   OR email LIKE '% %';

-- ---------------------------------------------------------
-- 2) AGREGACIÓN Y AGRUPAMIENTO
-- ---------------------------------------------------------

-- Paso 4: indicador de frecuencia (cuántas órdenes hizo cada cliente).
-- Es la "F" de Frequency en RFM.
-- LEFT JOIN para incluir a los clientes sin órdenes.
-- Decisión: se usa COUNT(o.order_id) y no COUNT(*).
--   Con LEFT JOIN, un cliente sin órdenes aparece en 1 fila con order_id NULL:
--   COUNT(*) contaría esa fila (daría 1); COUNT(o.order_id) ignora los NULL (da 0).
SELECT c.customer_id,
       c.full_name,
       COUNT(o.order_id) AS frecuencia
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY frecuencia DESC, c.customer_id;

-- Paso 5: valor monetario total gastado por cliente.
-- Es la "M" de Monetary en RFM.
-- Se encadenan 3 LEFT JOIN: customers → orders → order_items → products,
-- para no perder a los clientes sin compras.
-- SUM(quantity * price) suma lo gastado en todas sus órdenes.
-- Decisión: COALESCE convierte el NULL de los clientes sin compras en 0,
-- porque "no gastó nada" es 0, no un dato desconocido.
SELECT c.customer_id,
       c.full_name,
       COALESCE(SUM(oi.quantity * p.price), 0)::numeric(12,2) AS valor_monetario
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
LEFT JOIN products p     ON p.product_id = oi.product_id
GROUP BY c.customer_id, c.full_name
ORDER BY valor_monetario DESC;

-- Paso 6: dispersión de las cantidades vendidas por producto.
-- STDDEV mide cuánto varían las cantidades entre una venta y otra:
--   desvío alto → a veces se vende 1 unidad, a veces muchas (demanda variable).
--   desvío 0    → siempre se vende la misma cantidad.
-- Se muestran también la cantidad de ventas y el promedio, como contexto.
-- Decisión: el producto con una sola venta queda con desvío NULL
-- y no se reemplaza por 0. Con un solo dato no se puede medir variación:
-- NULL significa "no calculable", 0 significaría "no varía", y no es lo mismo.
-- NULLS LAST: en PostgreSQL, al ordenar DESC los NULL quedan primero
-- por defecto; así se mandan al final.
SELECT p.product_id,
       p.product_name,
       COUNT(*)                         AS cant_ventas,
       AVG(oi.quantity)::numeric(10,2)    AS promedio_unidades,
       STDDEV(oi.quantity)::numeric(10,2) AS desvio_unidades
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY desvio_unidades DESC NULLS LAST;

-- ---------------------------------------------------------
-- 3) CONSULTAS COMPUESTAS Y RELACIONES
-- ---------------------------------------------------------

-- Paso 7: listado de compras uniendo las 4 tablas.
-- Misma lógica que el caso 3, paso 1.
-- JOIN (INNER): solo trae compras completas
-- (cliente con orden, orden con ítems, ítem con producto).
SELECT c.full_name,
       o.order_id,
       o.order_date,
       p.product_name,
       p.category,
       oi.quantity,
       p.price,
       (oi.quantity * p.price)::numeric(12,2) AS subtotal
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
ORDER BY o.order_id, p.product_name;

-- Pasos 8 a 10: operaciones de conjuntos entre categorías.
-- Decisión: en lugar de repetir dos WITH en cada consulta (como en el caso 3),
-- se crea una vista con cada cliente y las categorías que compró.
-- Así las tres consultas quedan cortas y legibles.
-- DISTINCT: un cliente aparece una sola vez por categoría.
CREATE OR REPLACE VIEW vw_clientes_categoria AS
SELECT DISTINCT o.customer_id, p.category
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id;

-- Paso 8: clientes que compraron en las dos categorías (INTERSECT)
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Periféricos'
INTERSECT
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Pantallas';

-- Paso 9: clientes que compraron una u otra categoría (UNION, sin repetidos)
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Periféricos'
UNION
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Pantallas'
ORDER BY customer_id;

-- Paso 10: clientes que compraron Pantallas pero no Periféricos (EXCEPT)
-- Nota: al revés (Periféricos sin Pantallas) da 0 filas,
-- porque el único que compró Periféricos (Carlos) también compró Pantallas.
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Pantallas'
EXCEPT
SELECT customer_id FROM vw_clientes_categoria WHERE category = 'Periféricos';

-- ---------------------------------------------------------
-- 4) GESTIÓN DE BASES DE DATOS
-- ---------------------------------------------------------

-- Paso 11: índice sobre customer_id en orders.
-- Ya creado en el caso 4 (paso 2) como idx_orders_customer_id.
-- No se vuelve a crear; se verifica que existe.
-- (Si no existiera: CREATE INDEX idx_orders_customer_id ON orders(customer_id);)
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'orders'
ORDER BY indexname;

-- Paso 12: clave foránea de audit_logs a customers.
-- Inconsistencia: la consigna pide que user_info referencie a customers,
-- pero user_info tiene textos ('admin', 'postgres') que no son clientes,
-- y una FK exige que todos los valores existan en la tabla referenciada.
-- Decisión: se agrega la columna customer_id (INT, admite NULL)
-- con FK a customers.customer_id. user_info se conserva como está.

-- 12a) Agregar la columna con su FK
ALTER TABLE audit_logs
ADD COLUMN IF NOT EXISTS customer_id INT REFERENCES customers(customer_id);

-- 12b) Completarla donde se pueda:
-- user_info coincide con la parte del email anterior a la @
-- (SPLIT_PART(email, '@', 1) → 'carlos.perez').
-- UPDATE ... FROM: actualiza audit_logs usando datos de customers.
-- Los eventos de 'admin' y 'postgres' quedan en NULL: no son clientes.
UPDATE audit_logs a
SET customer_id = c.customer_id
FROM customers c
WHERE SPLIT_PART(c.email, '@', 1) = a.user_info;

-- 12c) Verificación
SELECT log_id, event_type, user_info, customer_id
FROM audit_logs
ORDER BY log_id;

-- 12b-previa) Vista previa: qué filas de audit_logs coinciden con un cliente.
-- Es un JOIN común: une audit_logs con customers
-- cuando user_info es igual a la parte del email antes de la @.
SELECT a.log_id,
       a.user_info,
       SPLIT_PART(c.email, '@', 1) AS usuario_del_email,
       c.customer_id
FROM audit_logs a
JOIN customers c ON SPLIT_PART(c.email, '@', 1) = a.user_info;

-- Paso 13: trigger que detecta cantidades inválidas en order_items.
-- Inconsistencia: si el trigger rechazara la fila con RAISE EXCEPTION,
-- el error deshace también el INSERT en audit_logs y el intento no queda registrado.
-- Decisión: trigger BEFORE INSERT que, si quantity <= 0,
--   1) registra 'ERROR_ORDER' en audit_logs (con el cliente de esa orden),
--   2) avisa con RAISE NOTICE,
--   3) descarta la fila con RETURN NULL (no se inserta, pero no hay error).
-- Si la cantidad es válida, RETURN NEW deja pasar la fila normalmente.

-- 13a) Función: qué hacer
CREATE OR REPLACE FUNCTION fn_validar_quantity()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quantity <= 0 THEN
    INSERT INTO audit_logs (event_type, event_timestamp, user_info, customer_id)
    VALUES ('ERROR_ORDER', NOW(), current_user,
            (SELECT customer_id FROM orders WHERE order_id = NEW.order_id));
    RAISE NOTICE 'Cantidad inválida (%) en la orden %: ítem descartado.',
                 NEW.quantity, NEW.order_id;
    RETURN NULL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 13b) Trigger: cuándo hacerlo (ANTES de insertar en order_items)
DROP TRIGGER IF EXISTS trg_validar_quantity ON order_items;

CREATE TRIGGER trg_validar_quantity
BEFORE INSERT ON order_items
FOR EACH ROW
EXECUTE FUNCTION fn_validar_quantity();

-- 13c) Prueba: insertar un ítem con cantidad 0 en la orden 1 (de Carlos).
-- Esperado: no da error, se inserta 0 filas, aparece el NOTICE en Output
-- y queda registrado 'ERROR_ORDER' en audit_logs.
INSERT INTO order_items (order_id, product_id, quantity)
VALUES (1, 2, 0);

-- 13d) Verificación 1: el intento quedó registrado en audit_logs
SELECT log_id, event_type, event_timestamp, user_info, customer_id
FROM audit_logs
ORDER BY log_id;

-- 13e) Verificación 2: el ítem inválido NO entró en order_items
SELECT COUNT(*) AS items_totales FROM order_items;

-- Paso 14: transacción completa con ROLLBACK.
-- Se da de alta un cliente nuevo, con una orden y dos ítems,
-- se comprueba que existen DENTRO de la transacción,
-- y después ROLLBACK deshace todo.
-- Como no se conocen de antemano los ID nuevos, se buscan con subconsultas:
--   el cliente por su email, y la orden como la última creada (MAX).
-- El trigger de auditoría también se dispara al insertar la orden,
-- y ese registro también se deshace con el ROLLBACK.

BEGIN;

INSERT INTO customers (full_name, email, created_at, first_name, last_name)
VALUES ('Ana Ruiz', 'ana.ruiz@email.com', CURRENT_DATE, 'Ana', 'Ruiz');

INSERT INTO orders (customer_id, order_date)
VALUES ((SELECT customer_id FROM customers WHERE email = 'ana.ruiz@email.com'),
        CURRENT_DATE);

INSERT INTO order_items (order_id, product_id, quantity)
VALUES ((SELECT MAX(order_id) FROM orders), 1, 1),
       ((SELECT MAX(order_id) FROM orders), 3, 2);

-- Dentro de la transacción: los datos existen (provisoriamente)
SELECT c.full_name, o.order_id, p.product_name, oi.quantity
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE c.email = 'ana.ruiz@email.com';

ROLLBACK;

-- Después del ROLLBACK: nada quedó guardado
SELECT (SELECT COUNT(*) FROM customers)   AS clientes,
       (SELECT COUNT(*) FROM orders)      AS ordenes,
       (SELECT COUNT(*) FROM order_items) AS items,
       (SELECT COUNT(*) FROM audit_logs)  AS logs;

-- ---------------------------------------------------------
-- 5) EXTRA MILE
-- ---------------------------------------------------------
-- Decisión de orden: primero se cargan datos nuevos (punto 3 de la consigna),
-- porque con los datos originales (todo en abril 2024, 3 clientes)
-- la vista por trimestre y la función de segmentos no tendrían qué mostrar.
-- Datos generados con IA, pensados para probar cada consulta:
--   - 2 categorías nuevas (Audio, Computadoras) para la vista.
--   - Carlos con 6 órdenes (Frecuente), Sofía con 3 (Ocasional), Pedro con 1 (Nuevo).
--   - 2 emails con errores a propósito (Pedro: espacio al final;
--     Valentina: sin @) para probar la detección del paso 3.

-- Paso 15a: productos y clientes nuevos
INSERT INTO products (product_name, category, price) VALUES
('Auriculares Bluetooth', 'Audio',        60.00),
('Webcam HD',             'Periféricos',  75.00),
('Notebook 14"',          'Computadoras', 850.00);

INSERT INTO customers (full_name, email, created_at, first_name, last_name) VALUES
('Sofía Díaz',      'sofia.diaz@email.com',     '2024-05-15', 'Sofía',     'Díaz'),
('Pedro Gómez',     'pedro.gomez@email.com ',   '2024-06-02', 'Pedro',     'Gómez'),
('Valentina López', 'valentina.lopezemail.com', '2024-07-20', 'Valentina', 'López');

-- Paso 15b: órdenes nuevas.
-- Técnica: INSERT ... SELECT con una tabla temporal escrita con VALUES.
--   (VALUES ...) AS v(email, fecha) arma una mini tabla con 2 columnas.
--   El JOIN con customers convierte cada email en su customer_id.
-- TRIM(c.email) para que el email de Pedro (con espacio al final) coincida.
-- El trigger trg_log_insert_order registra cada orden en audit_logs.
INSERT INTO orders (customer_id, order_date)
SELECT c.customer_id, v.fecha::date
FROM (VALUES
  ('carlos.perez@email.com',  '2024-05-10'),
  ('carlos.perez@email.com',  '2024-07-15'),
  ('carlos.perez@email.com',  '2024-09-03'),
  ('carlos.perez@email.com',  '2024-11-20'),
  ('sofia.diaz@email.com',    '2024-05-20'),
  ('sofia.diaz@email.com',    '2024-08-11'),
  ('sofia.diaz@email.com',    '2024-12-05'),
  ('pedro.gomez@email.com',   '2024-06-15')
) AS v(email, fecha)
JOIN customers c ON TRIM(c.email) = v.email;

-- Paso 15c: ítems de las órdenes nuevas.
-- Cada fila de VALUES: email del cliente, fecha de la orden, producto, cantidad.
-- Los JOIN convierten:
--   email + fecha    → order_id (la orden de ese cliente en esa fecha)
--   nombre producto  → product_id
-- Carlos compra 4 teclados en noviembre: sube la dispersión del Teclado (paso 6).
-- Todas las cantidades son > 0, así que el trigger de validación las deja pasar.
INSERT INTO order_items (order_id, product_id, quantity)
SELECT o.order_id, p.product_id, v.cantidad
FROM (VALUES
  ('carlos.perez@email.com', '2024-05-10', 'Auriculares Bluetooth', 1),
  ('carlos.perez@email.com', '2024-07-15', 'Webcam HD',             1),
  ('carlos.perez@email.com', '2024-07-15', 'Mouse Inalámbrico',     3),
  ('carlos.perez@email.com', '2024-09-03', 'Notebook 14"',          1),
  ('carlos.perez@email.com', '2024-11-20', 'Teclado Mecánico',      4),
  ('sofia.diaz@email.com',   '2024-05-20', 'Monitor 24"',           2),
  ('sofia.diaz@email.com',   '2024-08-11', 'Auriculares Bluetooth', 2),
  ('sofia.diaz@email.com',   '2024-12-05', 'Notebook 14"',          1),
  ('sofia.diaz@email.com',   '2024-12-05', 'Mouse Inalámbrico',     1),
  ('pedro.gomez@email.com',  '2024-06-15', 'Webcam HD',             1)
) AS v(email, fecha, producto, cantidad)
JOIN customers c ON TRIM(c.email) = v.email
JOIN orders o    ON o.customer_id = c.customer_id AND o.order_date = v.fecha::date
JOIN products p  ON p.product_name = v.producto;

-- Verificación: totales de la base después de la carga
SELECT (SELECT COUNT(*) FROM customers)   AS clientes,
       (SELECT COUNT(*) FROM products)    AS productos,
       (SELECT COUNT(*) FROM orders)      AS ordenes,
       (SELECT COUNT(*) FROM order_items) AS items,
       (SELECT COUNT(*) FROM audit_logs)  AS logs;

-- Re-ejecutado tras la carga del extra mile: detecta 2 (Pedro y Valentina).
-- Items 3a y 3b de verificacion de mails

-- Paso 16: vista dinámica de ventas por trimestre y categoría.
-- "Dinámica": una vista no guarda resultados; cada vez que se consulta
-- recalcula con los datos actuales. Si entran ventas nuevas, aparecen solas.
-- Por año + trimestre + categoría: ingresos, unidades y clientes distintos.
-- COUNT(DISTINCT customer_id): un cliente con varias compras cuenta una vez.
-- Decisión: "acumuladas" se interpreta como el total de cada trimestre.
-- Un acumulado progresivo (que vaya sumando trimestre a trimestre)
-- requiere funciones de ventana, un tema que todavía no se vio.
CREATE OR REPLACE VIEW vw_ventas_trimestre_categoria AS
SELECT EXTRACT(YEAR    FROM o.order_date)::int AS anio,
       EXTRACT(QUARTER FROM o.order_date)::int AS trimestre,
       p.category                              AS categoria,
       SUM(oi.quantity * p.price)::numeric(12,2) AS ingresos_totales,
       SUM(oi.quantity)                        AS unidades,
       COUNT(DISTINCT o.customer_id)           AS clientes_distintos
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY anio, trimestre, categoria;

-- Uso
SELECT * FROM vw_ventas_trimestre_categoria
ORDER BY anio, trimestre, categoria;

-- Paso 17: función que clasifica a cada cliente según su cantidad de órdenes.
--   Frecuente:   más de 5 órdenes
--   Ocasional:   entre 2 y 5
--   Nuevo:       1 orden
-- Inconsistencia: la consigna no contempla clientes con 0 órdenes.
-- Decisión: se agrega el segmento 'Sin compras', en lugar de dejarlos
-- en NULL o forzarlos en 'Nuevo' (no compraron nunca).
-- DECLARE v_ordenes: variable local donde se guarda el conteo.
-- SELECT ... INTO: guarda el resultado del COUNT en la variable.
CREATE OR REPLACE FUNCTION fn_segmento_cliente(p_customer_id INT)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
  v_ordenes INT;
BEGIN
  SELECT COUNT(*) INTO v_ordenes
  FROM orders
  WHERE customer_id = p_customer_id;

  RETURN CASE
           WHEN v_ordenes > 5            THEN 'Frecuente'
           WHEN v_ordenes BETWEEN 2 AND 5 THEN 'Ocasional'
           WHEN v_ordenes = 1            THEN 'Nuevo'
           ELSE 'Sin compras'
         END;
END;
$$;

-- Uso: la función se aplica a cada cliente dentro de un SELECT
SELECT c.customer_id,
       c.full_name,
       COUNT(o.order_id)                AS ordenes,
       fn_segmento_cliente(c.customer_id) AS segmento
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY ordenes DESC, c.customer_id;