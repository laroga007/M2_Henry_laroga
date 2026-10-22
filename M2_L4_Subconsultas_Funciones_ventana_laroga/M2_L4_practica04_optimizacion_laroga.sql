-- =============================================================================
-- M2 L4 · Práctica 4: Optimización y diagnóstico
-- Base: sqlplusdb (PostgreSQL)
-- Adaptado a las columnas reales de sqlplusdb (amount_paid; no existe students.active).
-- Sin BEGIN/COMMIT: DBeaver trabaja en Auto-commit.
-- Requiere haber creado vw_ultimo_progreso (Práctica 3, punto 0).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) Limitar resultados: últimos 5 pagos
-- Consulta: cuáles fueron los pagos más recientes.
-- Obtiene: los 5 últimos pagos, del más nuevo al más viejo.
-- Resultado esperado: los 5 pagos que hay (2023-03-22, 03-20, 02-10, 02-05, 01-15).
-- -----------------------------------------------------------------------------
SELECT payment_id, student_id, course_id, amount_paid, payment_date
FROM payments
ORDER BY payment_date DESC
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 2) Evitar duplicados con DISTINCT: estudiantes por curso
-- Consulta: qué estudiantes están inscriptos en cada curso.
-- Obtiene: cada par curso-estudiante una sola vez.
-- Resultado esperado: 6 filas (sin DISTINCT serían 8, por los duplicados de Marta y Luna).
-- Decisión: el script original filtraba por students.active, columna que no existe en sqlplusdb.
-- Nota: DISTINCT puede tapar un JOIN mal armado; usarlo cuando la repetición es esperable.
-- -----------------------------------------------------------------------------
SELECT DISTINCT c.course_id,
       c.course_name,
       s.student_id,
       s.full_name
FROM enrollments e
JOIN students s ON s.student_id = e.student_id
JOIN courses c ON c.course_id = e.course_id
ORDER BY c.course_id, s.student_id;


-- -----------------------------------------------------------------------------
-- 3) Pivot de estados de inscripción por curso (en lugar de PIVOT, que no existe en PostgreSQL)
-- Consulta: cuántos inscriptos tiene cada curso y cuántos lo completaron o no.
-- Obtiene: una fila por curso con tres columnas de conteo.
-- Resultado esperado: SQL para principiantes 3/3/0 (inflado por el duplicado de Marta),
--                     Data Science 1/0/1, Tableau 2/0/2 (duplicado de Luna),
--                     SQL Avanzado 1/0/1, Power BI 1/0/1.
-- -----------------------------------------------------------------------------
SELECT c.course_id,
       c.course_name,
       COUNT(*) AS inscriptos,
       COUNT(*) FILTER (WHERE e.completed) AS completados,
       COUNT(*) FILTER (WHERE NOT e.completed) AS no_completados
FROM enrollments e
JOIN courses c ON c.course_id = e.course_id
GROUP BY c.course_id, c.course_name
ORDER BY c.course_id;


-- -----------------------------------------------------------------------------
-- 4) Rendimiento con EXPLAIN ANALYZE, antes y después de un índice
-- Consulta: cómo resuelve PostgreSQL la búsqueda de inscripciones de un curso.
-- Obtiene: el plan de ejecución (Seq Scan = recorre toda la tabla;
--          Index Scan = usa el índice) y el tiempo (Execution Time).
-- Resultado esperado: Seq Scan en los dos casos. Con 8 filas, recorrer la tabla
--                     es más rápido que usar el índice; con tablas grandes cambiaría.
-- Ojo: EXPLAIN ANALYZE ejecuta la consulta de verdad (con UPDATE o DELETE modifica datos).
-- -----------------------------------------------------------------------------

-- Antes del índice
EXPLAIN ANALYZE
SELECT * FROM enrollments WHERE course_id = 2;

-- Crear el índice
CREATE INDEX IF NOT EXISTS idx_enrollments_course_id ON enrollments(course_id);

-- Después del índice
EXPLAIN ANALYZE
SELECT * FROM enrollments WHERE course_id = 2;


-- -----------------------------------------------------------------------------
-- 5) Evaluar una consulta generada por IA y corregirla
-- -----------------------------------------------------------------------------
-- Vista propuesta por la IA (NO ejecutar, tiene errores):
/*
CREATE OR REPLACE VIEW vw_student_overview AS
SELECT s.id AS student_id, s.name AS student_name,
       SUM(pay.amount_paid) AS total_paid,
       AVG(prog.progress) AS avg_progress,
       COUNT(rev.id) AS review_count,
       MAX(rev.date) AS last_review_date
FROM student s
LEFT JOIN payment pay ON pay.sid = s.id
LEFT JOIN prog prog ON prog.sid = s.id
LEFT JOIN review rev ON rev.sid = s.id
GROUP BY s.id, s.name;
*/
-- Problemas:
--  - Tablas y columnas que no existen (student, payment, s.id, s.name, sid, progress).
--  - Une pagos, avances y reseñas a la vez por estudiante: si alguien tiene 2 pagos
--    y 2 reseñas, el JOIN genera 4 combinaciones y SUM cuenta cada pago dos veces.
--  - Mezcla todos los cursos del estudiante sin distinguirlos.
-- Corrección: calcular cada métrica por separado (una CTE cada una), a nivel
--             estudiante-curso, y recién después unirlas.


-- 5a) Vista corregida: resumen por estudiante y curso
-- Consulta: para cada inscripción, cómo va el estudiante en ese curso.
-- Obtiene: avance, total pagado, cantidad de reseñas y fecha de la última.
-- Resultado esperado (SELECT de abajo): 6 filas →
--   Marta / SQL principiantes: sin avance, 50, 0
--   Marta / Data Science: 40, 120, 2 (reseña duplicada)
--   Tomás / SQL principiantes: sin avance, 50, 1
--   Luna / Tableau: 25, 0, 1 (cursa, reseña y no pagó)
--   Diego / SQL Avanzado: 10, 90, 0
--   María José / Power BI: 5, 100, 0
-- Decisión: DISTINCT en inscripciones para no duplicar filas por los registros repetidos.
CREATE OR REPLACE VIEW vw_resumen_estudiante_curso AS
WITH inscripciones AS (
    SELECT DISTINCT student_id, course_id
    FROM enrollments
),
pagos AS (
    SELECT student_id, course_id, SUM(amount_paid) AS total_pagado
    FROM payments
    GROUP BY student_id, course_id
),
resenias AS (
    SELECT student_id, course_id,
           COUNT(*) AS cant_resenias,
           MAX(review_date) AS ultima_resenia
    FROM reviews
    GROUP BY student_id, course_id
)
SELECT i.student_id,
       s.full_name,
       i.course_id,
       c.course_name,
       up.percentage_completed AS avance,
       COALESCE(pa.total_pagado, 0) AS total_pagado,
       COALESCE(re.cant_resenias, 0) AS cant_resenias,
       re.ultima_resenia
FROM inscripciones i
JOIN students s ON s.student_id = i.student_id
JOIN courses c ON c.course_id = i.course_id
LEFT JOIN vw_ultimo_progreso up ON up.student_id = i.student_id AND up.course_id = i.course_id
LEFT JOIN pagos pa ON pa.student_id = i.student_id AND pa.course_id = i.course_id
LEFT JOIN resenias re ON re.student_id = i.student_id AND re.course_id = i.course_id;

SELECT * FROM vw_resumen_estudiante_curso ORDER BY student_id, course_id;


-- 5b) Vista resumen por estudiante (se apoya en la anterior)
-- Consulta: cómo va cada estudiante en total.
-- Obtiene: avance promedio, total pagado y cantidad de reseñas por estudiante.
-- Resultado esperado: Marta 40 / 170 / 2, Tomás sin avance / 50 / 1, Luna 25 / 0 / 1,
--                     Diego 10 / 90 / 0, María José 5 / 100 / 0; del 6 al 10 sin avance / 0 / 0.
-- Decisión: el avance sin dato queda NULL y no 0 (no tener registro no es lo mismo que 0 %).
CREATE OR REPLACE VIEW vw_resumen_estudiante AS
SELECT s.student_id,
       s.full_name,
       ROUND(AVG(v.avance), 2) AS avance_promedio,
       COALESCE(SUM(v.total_pagado), 0) AS total_pagado,
       COALESCE(SUM(v.cant_resenias), 0) AS cant_resenias,
       MAX(v.ultima_resenia) AS ultima_resenia
FROM students s
LEFT JOIN vw_resumen_estudiante_curso v ON v.student_id = s.student_id
GROUP BY s.student_id, s.full_name;

SELECT * FROM vw_resumen_estudiante ORDER BY student_id;
