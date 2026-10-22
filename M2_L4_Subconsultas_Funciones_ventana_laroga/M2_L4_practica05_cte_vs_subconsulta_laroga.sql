-- =============================================================================
-- M2 L4 · Práctica 5: CTE vs subconsultas (legibilidad, reutilización y recursión)
-- Base: sqlplusdb (PostgreSQL)
-- Adaptado: el script original usa las tablas books y employees, que no existen
-- en sqlplusdb. Los productos pasan a ser courses; los empleados se arman con VALUES.
-- Sin BEGIN/COMMIT: DBeaver trabaja en Auto-commit.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1) Cursos con precio mayor al promedio de su categoría
-- Consulta: qué cursos son más caros que el promedio de su propia categoría.
-- Obtiene: esos cursos con su categoría y precio. Las dos opciones dan lo mismo.
-- Resultado esperado: 2 filas →
--   SQL Avanzado (Bases de Datos, 90; promedio de la categoría 70)
--   Power BI para Negocios (Business Intelligence, 100; promedio 90)
-- Nota: las categorías sucias ('bases de datos', 'BI', 'Business intelligence '
--       con espacio final) forman grupos propios de un solo curso, así que no
--       pueden superar su propio promedio.
-- -----------------------------------------------------------------------------

-- Opción A: subconsulta correlacionada (se recalcula el promedio para cada curso)
SELECT c.course_id, c.course_name, c.category, c.price
FROM courses c
WHERE c.price > (SELECT AVG(c2.price)
                 FROM courses c2
                 WHERE c2.category = c.category)
ORDER BY c.category, c.price DESC;

-- Opción B: CTE (el promedio por categoría se calcula una vez y se une)
WITH promedio_categoria AS (
    SELECT category, AVG(price) AS precio_promedio
    FROM courses
    GROUP BY category
)
SELECT c.course_id, c.course_name, c.category, c.price
FROM courses c
JOIN promedio_categoria pc ON pc.category = c.category
WHERE c.price > pc.precio_promedio
ORDER BY c.category, c.price DESC;


-- -----------------------------------------------------------------------------
-- 2) Reutilizar la CTE: cuántos cursos superan el promedio en cada categoría
-- Consulta: en qué categorías hay cursos por encima del promedio, y cuántos.
-- Obtiene: por categoría, la cantidad de cursos sobre el promedio y el promedio.
-- Resultado esperado: Bases de Datos 1 (promedio 70.00);
--                     Business Intelligence 1 (promedio 90.00).
-- Cómo se reutiliza: promedio_categoria se usa dos veces, dentro de
--                    sobre_promedio y en el JOIN final.
-- -----------------------------------------------------------------------------
WITH promedio_categoria AS (
    SELECT category, AVG(price) AS precio_promedio
    FROM courses
    GROUP BY category
),
sobre_promedio AS (
    SELECT c.category, c.course_id
    FROM courses c
    JOIN promedio_categoria pc ON pc.category = c.category
    WHERE c.price > pc.precio_promedio
)
SELECT sp.category,
       COUNT(*) AS cursos_sobre_promedio,
       ROUND(pc.precio_promedio, 2) AS promedio_categoria
FROM sobre_promedio sp
JOIN promedio_categoria pc ON pc.category = sp.category
GROUP BY sp.category, pc.precio_promedio
ORDER BY cursos_sobre_promedio DESC, sp.category;


-- -----------------------------------------------------------------------------
-- 3) CTE recursiva: jerarquía de empleados a partir de un jefe
-- Consulta: quiénes dependen, directa o indirectamente, de la Directora (id 1).
-- Obtiene: cada empleado con su nivel de dependencia (1 = directo).
-- Resultado esperado: nivel 1 Coordinador académico y Coordinadora comercial;
--                     nivel 2 Tutor SQL, Tutora Python y Vendedor.
-- Decisión: sqlplusdb no tiene tabla de empleados; se inventa con VALUES
--           (id, id del jefe, nombre). Es el mismo patrón que los
--           prerrequisitos de la Práctica 2, punto 4.
-- -----------------------------------------------------------------------------
WITH RECURSIVE
empleados (employee_id, manager_id, name) AS (
    VALUES (1, NULL::INT, 'Directora'),
           (2, 1, 'Coordinador académico'),
           (3, 1, 'Coordinadora comercial'),
           (4, 2, 'Tutor SQL'),
           (5, 2, 'Tutora Python'),
           (6, 3, 'Vendedor')
),
jerarquia AS (
    -- Ancla: quienes dependen directamente del jefe 1
    SELECT employee_id, manager_id, name, 1 AS nivel
    FROM empleados
    WHERE manager_id = 1
    UNION ALL
    -- Paso: quienes dependen de los ya encontrados (corta cuando no hay más)
    SELECT e.employee_id, e.manager_id, e.name, j.nivel + 1
    FROM empleados e
    JOIN jerarquia j ON e.manager_id = j.employee_id
)
SELECT nivel, name, manager_id
FROM jerarquia
ORDER BY nivel, name;
