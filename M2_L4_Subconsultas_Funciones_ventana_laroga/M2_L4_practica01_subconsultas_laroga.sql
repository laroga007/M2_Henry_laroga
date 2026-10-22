-- =============================================================================
-- M2 L4 · Práctica 1: Subconsultas y comparación con JOIN
-- Base: sqlplusdb (PostgreSQL)
-- Adaptado a las columnas reales de sqlplusdb (payment_date, review_date).
-- Sin BEGIN/COMMIT: DBeaver trabaja en Auto-commit.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) Pago máximo por estudiante (subconsulta escalar correlacionada en el SELECT)
-- Consulta: cuál fue el pago más alto de cada estudiante.
-- Obtiene: todos los estudiantes con su pago máximo; NULL si nunca pagó.
-- Resultado esperado: Marta 120, María José 100, Diego 90, Tomás 50;
--                     Luna y los estudiantes 6 a 10 en NULL.
-- -----------------------------------------------------------------------------
SELECT s.student_id,
       s.full_name,
       (SELECT MAX(p.amount_paid)
        FROM payments p
        WHERE p.student_id = s.student_id) AS max_pago
FROM students s
ORDER BY max_pago DESC NULLS LAST, s.student_id;


-- -----------------------------------------------------------------------------
-- 2) Estudiantes con algún pago superior al promedio global (subconsulta en WHERE)
-- Consulta: quiénes hicieron al menos un pago por encima del pago promedio.
-- Obtiene: la lista de esos estudiantes, cada uno una sola vez.
-- Resultado esperado: promedio = 82 → Marta (120), Diego (90), María José (100).
-- Decisión: se usa IN en lugar de JOIN + DISTINCT; IN no repite estudiantes,
--           así que no hace falta DISTINCT.
-- -----------------------------------------------------------------------------
SELECT s.student_id, s.full_name
FROM students s
WHERE s.student_id IN (SELECT p.student_id
                       FROM payments p
                       WHERE p.amount_paid > (SELECT AVG(amount_paid) FROM payments))
ORDER BY s.full_name;


-- -----------------------------------------------------------------------------
-- 3) Cursos con reseñas pero sin pagos: tres formas de resolverlo
-- Consulta: qué cursos fueron reseñados pero nunca recibieron un pago.
-- Obtiene: esos cursos. Las tres versiones dan lo mismo.
-- Resultado esperado: curso 3, Visualización con Tableau (el caso de Luna).
-- -----------------------------------------------------------------------------

-- 3A) Con IN / NOT IN
-- Ojo: NOT IN devuelve vacío si la subconsulta trae algún NULL.
SELECT c.course_id, c.course_name
FROM courses c
WHERE c.course_id IN (SELECT r.course_id FROM reviews r)
  AND c.course_id NOT IN (SELECT p.course_id FROM payments p)
ORDER BY c.course_name;

-- 3B) Con LEFT JOIN + IS NULL ("anti-join")
-- El LEFT JOIN trae los pagos del curso; si no hay ninguno, p.course_id queda NULL.
-- DISTINCT porque el JOIN con reviews repetiría el curso si tuviera varias reseñas.
SELECT DISTINCT c.course_id, c.course_name
FROM courses c
JOIN reviews r ON r.course_id = c.course_id
LEFT JOIN payments p ON p.course_id = c.course_id
WHERE p.course_id IS NULL
ORDER BY c.course_name;

-- 3C) Con EXISTS / NOT EXISTS (la opción recomendada: no tiene el problema de los NULL)
SELECT c.course_id, c.course_name
FROM courses c
WHERE EXISTS (SELECT 1 FROM reviews r WHERE r.course_id = c.course_id)
  AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.course_id = c.course_id)
ORDER BY c.course_name;


-- -----------------------------------------------------------------------------
-- 4) Reseñas de cursos aún no completados (subconsulta correlacionada con EXISTS)
-- Consulta: qué reseñas dejaron estudiantes que todavía no terminaron ese curso.
-- Obtiene: cada reseña con estudiante, curso, puntaje y comentario.
-- Resultado esperado: 3 filas → Luna (Tableau) y Marta (Data Science) dos veces,
--                     porque su reseña está duplicada. La de Tomás no sale: completó el curso.
-- Nota: en PostgreSQL, completed es boolean → se compara con false, no con 0.
-- -----------------------------------------------------------------------------
SELECT r.review_id,
       s.full_name AS estudiante,
       c.course_name,
       r.rating,
       r.comment,
       r.review_date
FROM reviews r
JOIN students s ON s.student_id = r.student_id
JOIN courses c ON c.course_id = r.course_id
WHERE EXISTS (SELECT 1
              FROM enrollments e
              WHERE e.student_id = r.student_id
                AND e.course_id = r.course_id
                AND e.completed = false)
ORDER BY r.review_date DESC;
