-- =============================================================================
-- M2 L4 · Práctica 2: CTE encadenadas y recursiva
-- Base: sqlplusdb (PostgreSQL)
-- Adaptado a las columnas reales de sqlplusdb (percentage_completed).
-- Sin BEGIN/COMMIT: DBeaver trabaja en Auto-commit.
-- Cada WITH va junto con su SELECT: seleccionar el bloque completo hasta el ";".
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) Estudiantes con al menos un curso completado y su promedio de avance
-- Consulta: quiénes terminaron algún curso y cuánto avanzan en promedio.
-- Obtiene: esos estudiantes con su avance promedio (NULL si no hay registro de avance).
-- Resultado esperado: Marta 40.00 y Tomás NULL.
-- Hallazgo: Tomás completó el curso 1 pero no tiene ningún registro en progress.
-- -----------------------------------------------------------------------------
WITH promedio_avance AS (
    SELECT student_id,
           ROUND(AVG(percentage_completed), 2) AS avance_promedio
    FROM progress
    GROUP BY student_id
),
completaron AS (
    SELECT DISTINCT student_id
    FROM enrollments
    WHERE completed = true
)
SELECT s.student_id,
       s.full_name,
       pa.avance_promedio
FROM completaron co
JOIN students s ON s.student_id = co.student_id
LEFT JOIN promedio_avance pa ON pa.student_id = s.student_id
ORDER BY pa.avance_promedio DESC NULLS LAST, s.student_id;


-- -----------------------------------------------------------------------------
-- 2) Cursos inscriptos, completados y no completados por estudiante
-- Consulta: cómo le va a cada estudiante con sus inscripciones.
-- Obtiene: por estudiante, cuántas inscripciones tiene, cuántas completó y cuántas no.
-- Resultado esperado: Marta 3/2/1 (inflado por su duplicado), Tomás 1/1/0,
--                     Luna 2/0/2 (duplicado), Diego 1/0/1, María José 1/0/1, del 6 al 10 en 0.
-- Decisión: una sola CTE con FILTER en lugar de tres CTE separadas (más simple).
--           FILTER cuenta solo las filas que cumplen la condición.
-- -----------------------------------------------------------------------------
WITH resumen AS (
    SELECT student_id,
           COUNT(*) AS inscriptos,
           COUNT(*) FILTER (WHERE completed) AS completados,
           COUNT(*) FILTER (WHERE NOT completed) AS no_completados
    FROM enrollments
    GROUP BY student_id
)
SELECT s.student_id,
       s.full_name,
       COALESCE(r.inscriptos, 0) AS inscriptos,
       COALESCE(r.completados, 0) AS completados,
       COALESCE(r.no_completados, 0) AS no_completados
FROM students s
LEFT JOIN resumen r ON r.student_id = s.student_id
ORDER BY completados DESC, inscriptos DESC, s.student_id;


-- -----------------------------------------------------------------------------
-- 3) Cursos con calificación promedio menor a 4 y baja tasa de finalización (< 50 %)
-- Consulta: qué cursos están mal calificados y además casi nadie los termina.
-- Obtiene: esos cursos con su promedio de rating, tasa de finalización y cantidades.
-- Resultado esperado: VACÍO. El rating más bajo es Tableau con 4.00, y 4 no es menor que 4.
--                     Para probar que funciona, cambiar "< 4" por "< 4.5": aparece Tableau
--                     (rating 4.00, finalización 0.00).
-- -----------------------------------------------------------------------------
WITH ratings AS (
    SELECT course_id,
           ROUND(AVG(rating), 2) AS rating_promedio,
           COUNT(*) AS cant_resenias
    FROM reviews
    GROUP BY course_id
),
finalizacion AS (
    SELECT course_id,
           ROUND(AVG(CASE WHEN completed THEN 1.0 ELSE 0.0 END), 2) AS tasa_finalizacion,
           COUNT(*) AS cant_inscripciones
    FROM enrollments
    GROUP BY course_id
)
SELECT c.course_id,
       c.course_name,
       ra.rating_promedio,
       f.tasa_finalizacion,
       ra.cant_resenias,
       f.cant_inscripciones
FROM courses c
JOIN ratings ra ON ra.course_id = c.course_id
JOIN finalizacion f ON f.course_id = c.course_id
WHERE ra.rating_promedio < 4
  AND f.tasa_finalizacion < 0.5
ORDER BY ra.rating_promedio, f.tasa_finalizacion;


-- -----------------------------------------------------------------------------
-- 4) CTE recursiva: cadena de prerrequisitos de un curso
-- Consulta: qué cursos hay que hacer antes de "Data Science con Python" (curso 2).
-- Obtiene: los prerrequisitos en orden de profundidad (nivel 1 = directo).
-- Resultado esperado: nivel 1 SQL Avanzado, nivel 2 SQL para principiantes.
-- Decisión: sqlplusdb no tiene tabla de prerrequisitos, así que se inventan
--           en una CTE con VALUES (curso, curso que requiere):
--           Data Science (2) requiere SQL Avanzado (4);
--           SQL Avanzado (4) requiere SQL para principiantes (1);
--           Power BI (5) requiere Tableau (3).
-- -----------------------------------------------------------------------------
WITH RECURSIVE
prerrequisitos (course_id, prereq_course_id) AS (
    VALUES (2, 4),
           (4, 1),
           (5, 3)
),
cadena AS (
    -- Ancla: prerrequisitos directos del curso 2
    SELECT prereq_course_id AS curso_id, 1 AS nivel
    FROM prerrequisitos
    WHERE course_id = 2
    UNION ALL
    -- Paso: prerrequisitos de los prerrequisitos (corta solo cuando no hay más)
    SELECT p.prereq_course_id, ca.nivel + 1
    FROM prerrequisitos p
    JOIN cadena ca ON p.course_id = ca.curso_id
)
SELECT ca.nivel, c.course_name
FROM cadena ca
JOIN courses c ON c.course_id = ca.curso_id
ORDER BY ca.nivel;
