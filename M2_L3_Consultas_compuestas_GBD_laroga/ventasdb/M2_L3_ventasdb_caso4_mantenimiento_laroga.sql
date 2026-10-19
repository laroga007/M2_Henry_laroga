-- =========================================================
-- Caso 4: Mantenimiento, índices, triggers y transacciones (ventasdb)
-- =========================================================

-- 1) INTEGRIDAD DE DATOS

-- Paso 1: comprobar que las FOREIGN KEY protegen la base.
-- ventasdb ya tiene PK y FK desde el script inicial.
-- Los dos INSERT tienen que dar ERROR a propósito:
-- la base no acepta datos que apunten a registros inexistentes.

-- 1a) Orden para un cliente que no existe (cliente 99)
INSERT INTO orders (customer_id, order_date)
VALUES (99, '2024-05-01');

-- 1b) Ítem de un producto que no existe (producto 999)
INSERT INTO order_items (order_id, product_id, quantity)
VALUES (1, 999, 1);

-- 2) OPTIMIZACIÓN DE CONSULTAS

-- Paso 2: índices en las columnas que más se usan en filtros y JOIN.
-- IF NOT EXISTS evita el error si el índice ya existe.
-- Convención de nombre: idx_tabla_columna.
CREATE INDEX IF NOT EXISTS idx_orders_order_date      ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id     ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_products_category      ON products(category);

-- Índice de expresión: se arma sobre el email ya limpio
-- (minúsculas y sin espacios), no sobre la columna tal cual.
CREATE INDEX IF NOT EXISTS idx_customers_email_norm   ON customers (LOWER(TRIM(email)));

-- Verificación: lista todos los índices de la base.
-- pg_indexes es una tabla del sistema de PostgreSQL.
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 3) AUTOMATIZACIÓN: TRIGGER DE AUDITORÍA

-- Paso 3a: función que registra el evento en audit_logs.
-- RETURNS TRIGGER indica que es una función para usar en un trigger.
-- NOW() guarda la fecha y hora; current_user, el usuario conectado.
-- RETURN NEW devuelve la fila insertada (obligatorio en triggers de fila).
CREATE OR REPLACE FUNCTION fn_log_insert_order()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs(event_type, event_timestamp, user_info)
  VALUES ('INSERT_ORDER', NOW(), current_user);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Paso 3b: trigger que llama a la función después de cada INSERT en orders.
-- DROP TRIGGER IF EXISTS borra el trigger si ya existía,
-- para poder volver a crearlo sin error.
DROP TRIGGER IF EXISTS trg_log_insert_order ON orders;

CREATE TRIGGER trg_log_insert_order
AFTER INSERT ON orders
FOR EACH ROW
EXECUTE FUNCTION fn_log_insert_order();

-- Paso 3c: prueba del trigger.
-- Se inserta una orden; el trigger tiene que registrarla solo en audit_logs.
-- RETURNING muestra el order_id que se asignó.
-- (Modifica la base: queda una orden de prueba sin ítems.)
INSERT INTO orders (customer_id, order_date)
VALUES (2, CURRENT_DATE)
RETURNING order_id;

-- Verificación: el último registro de audit_logs tiene que ser
-- INSERT_ORDER con la fecha y hora de hoy, sin haberlo escrito a mano.
SELECT * FROM audit_logs
ORDER BY log_id;

-- 4) TRANSACCIÓN: TODO O NADA

-- Paso 4: alta de una orden con dos ítems; el segundo es inválido.
-- DECLARE crea la variable v_order_id (variable local).
-- RETURNING ... INTO guarda en la variable el número de la orden nueva.
-- Al fallar el producto 999, EXCEPTION atrapa el error de FK
-- y deshace TODO el bloque: la orden, el ítem válido
-- y el registro que había agregado el trigger.
-- RAISE NOTICE muestra el aviso en el panel Output.
DO $$
DECLARE
  v_order_id INT;
BEGIN
  BEGIN
    INSERT INTO orders(customer_id, order_date)
    VALUES (1, CURRENT_DATE)
    RETURNING order_id INTO v_order_id;

    INSERT INTO order_items(order_id, product_id, quantity)
    VALUES
      (v_order_id, 1, 2),
      (v_order_id, 999, 1);   -- producto inexistente: fuerza el error
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'Rollback por FK inválida en order_items.';
  END;
END $$;

-- Verificación: no tiene que haber quedado nada de la orden fallida.
SELECT order_id, customer_id, order_date FROM orders ORDER BY order_id;
SELECT COUNT(*) AS filas_audit FROM audit_logs;

-- 5) VISTAS (reportes guardados)

-- Paso 5a: ingresos por mes.
-- Es la misma lógica del resumen mensual del caso 1, guardada con nombre.
CREATE OR REPLACE VIEW vw_ingresos_por_mes AS
SELECT DATE_TRUNC('month', o.order_date)::date AS mes,
       SUM(oi.quantity * p.price)::numeric(12,2) AS ingresos
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
GROUP BY 1;

-- Paso 5b: ranking de clientes por unidades compradas.
-- Es la consulta del caso 2, paso 4, guardada con nombre.
CREATE OR REPLACE VIEW vw_ranking_clientes AS
SELECT o.customer_id,
       c.full_name,
       SUM(oi.quantity) AS unidades
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN customers c    ON c.customer_id = o.customer_id
GROUP BY o.customer_id, c.full_name
ORDER BY unidades DESC;

-- Uso: se consultan como una tabla.
SELECT * FROM vw_ingresos_por_mes;
SELECT * FROM vw_ranking_clientes;
