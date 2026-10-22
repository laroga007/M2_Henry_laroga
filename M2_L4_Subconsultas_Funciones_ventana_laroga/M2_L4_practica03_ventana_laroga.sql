-- =============================================================================
-- M2 L4 · Práctica 3: Funciones de ventana (ranking, evolución, primeras y últimas)
-- Base: sqlplusdb (PostgreSQL)
-- Adaptado a las columnas reales de sqlplusdb (last_access_date, percentage_completed).
-- Sin BEGIN/COMMIT: DBeaver trabaja en Auto-commit.
-- Nota sobre los datos: progress tiene un solo registro por estudiante y curso,
-- así que los rankings dan todos 1 y LAG/LEAD dan NULL. La sintaxis queda lista
-- para cuando haya más datos.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 0) Vista base: último avance de cada estudiante en cada curso
-- Consulta: cuál es el avance más reciente de cada estudiante en cada curso.
-- Obtiene: una vista reutilizable con una fila por estudiante y curso.
-- Resultado esperado: 4 filas (Marta 40, Luna 25, Diego 10, María José 5).
-- Decisión: en el script original era una CTE suelta, pero una CTE solo vale
--           para la sentencia en la que está escrita; las consultas siguientes
--           no la encontrarían. Por eso se guarda como vista.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_ultimo_progreso AS
WITH numerado AS (
    SELECT student_id,
           course_id,
           percentage_completed,
           last_access_date,
           ROW_NUMBER() OVER (PARTITION BY student_id, course_id
                              ORDER BY last_access_date DESC) AS rn
    FROM progress
)
SELECT student_id, course_id, percentage_completed, last_access_date
FROM numerado
WHERE rn = 1;

SELECT * FROM vw_ultimo_progreso;


-- -----------------------------------------------------------------------------
-- 1a) Ranking por curso con ROW_NUMBER (sin empates: posiciones únicas)
-- Consulta: quién va más avanzado dentro de cada curso.
-- Obtiene: cada estudiante con su posición en su curso.
-- Resultado esperado: 4 filas, todas en posición 1 (un estudiante por curso).
-- -----------------------------------------------------------------------------
SELECT c.course_name,
       s.full_name,
       up.percentage_completed,
       ROW_NUMBER() OVER (PARTITION BY up.course_id
                          ORDER BY up.percentage_completed DESC, up.student_id) AS posicion
FROM vw_ultimo_progreso up
JOIN students s ON s.student_id = up.student_id
JOIN courses c ON c.course_id = up.course_id
ORDER BY c.course_name, posicion;


-- -----------------------------------------------------------------------------
-- 1b) Ranking por curso con RANK y DENSE_RANK (con empates)
-- Consulta: lo mismo, pero respetando empates.
-- Obtiene: RANK saltea puestos tras un empate (1, 1, 3); DENSE_RANK no (1, 1, 2).
-- Resultado esperado: 4 filas, todas en 1 y 1.
-- -----------------------------------------------------------------------------
SELECT c.course_name,
       s.full_name,
       up.percentage_completed,
       RANK() OVER (PARTITION BY up.course_id
                    ORDER BY up.percentage_completed DESC) AS puesto_rank,
       DENSE_RANK() OVER (PARTITION BY up.course_id
                          ORDER BY up.percentage_completed DESC) AS puesto_dense_rank
FROM vw_ultimo_progreso up
JOIN students s ON s.student_id = up.student_id
JOIN courses c ON c.course_id = up.course_id
ORDER BY c.course_name, puesto_rank;


-- -----------------------------------------------------------------------------
-- 1c) Top 3 por curso, respetando empates
-- Consulta: los 3 más avanzados de cada curso.
-- Obtiene: solo las filas con puesto 3 o menor.
-- Resultado esperado: las mismas 4 filas.
-- Por qué la CTE: un WHERE no puede filtrar directamente por una función de ventana;
--                 primero se calcula el puesto en la CTE y después se filtra.
-- -----------------------------------------------------------------------------
WITH ranking AS (
    SELECT c.course_name,
           s.full_name,
           up.percentage_completed,
           RANK() OVER (PARTITION BY up.course_id
                        ORDER BY up.percentage_completed DESC) AS puesto
    FROM vw_ultimo_progreso up
    JOIN students s ON s.student_id = up.student_id
    JOIN courses c ON c.course_id = up.course_id
)
SELECT *
FROM ranking
WHERE puesto <= 3
ORDER BY course_name, puesto;


-- -----------------------------------------------------------------------------
-- 2) Evolución del avance con LAG y LEAD
-- Consulta: cuánto avanzó cada estudiante desde su registro anterior y cuándo volvió.
-- Obtiene: avance anterior, diferencia de avance, días desde el acceso anterior
--          y fecha del próximo acceso.
-- Resultado esperado: 4 filas con esas columnas en NULL (no hay registro anterior ni siguiente).
-- Decisión: WINDOW w define la ventana una sola vez y se reutiliza con "OVER w",
--           en lugar de repetir PARTITION BY ... ORDER BY ... en cada columna.
-- -----------------------------------------------------------------------------
SELECT s.full_name,
       c.course_name,
       p.last_access_date,
       p.percentage_completed,
       LAG(p.percentage_completed) OVER w AS avance_anterior,
       p.percentage_completed - LAG(p.percentage_completed) OVER w AS diferencia_avance,
       p.last_access_date - LAG(p.last_access_date) OVER w AS dias_desde_anterior,
       LEAD(p.last_access_date) OVER w AS proximo_acceso
FROM progress p
JOIN students s ON s.student_id = p.student_id
JOIN courses c ON c.course_id = p.course_id
WINDOW w AS (PARTITION BY p.student_id, p.course_id ORDER BY p.last_access_date)
ORDER BY s.full_name, c.course_name, p.last_access_date;


-- -----------------------------------------------------------------------------
-- 3) Primera y última reseña de cada curso con FIRST_VALUE y LAST_VALUE
-- Consulta: quién reseñó primero y quién último cada curso, y cuándo.
-- Obtiene: una fila por curso con la primera y la última reseña.
-- Resultado esperado: 3 filas → SQL para principiantes: Tomás / Tomás (2023-02-07);
--                     Data Science: Marta / Marta (2023-02-25); Tableau: Luna / Luna (2023-03-22).
-- Ojo: sin "ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING",
--      LAST_VALUE devolvería la fila actual y no la última del curso.
-- DISTINCT: la ventana repite el mismo dato en cada reseña del curso; se deja una fila.
-- -----------------------------------------------------------------------------
SELECT DISTINCT r.course_id,
       c.course_name,
       FIRST_VALUE(s.full_name) OVER w AS primera_resenia_de,
       FIRST_VALUE(r.review_date) OVER w AS primera_fecha,
       LAST_VALUE(s.full_name) OVER w AS ultima_resenia_de,
       LAST_VALUE(r.review_date) OVER w AS ultima_fecha
FROM reviews r
JOIN courses c ON c.course_id = r.course_id
JOIN students s ON s.student_id = r.student_id
WINDOW w AS (PARTITION BY r.course_id
             ORDER BY r.review_date
             ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
ORDER BY r.course_id;
