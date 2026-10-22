# Lecture 4: subconsultas, CTE, funciones de ventana y optimización

Práctica del Módulo 2 (SQL) de Henry Data Science, en **PostgreSQL** con DBeaver. Se trabaja sobre `sqlplusdb`, una base de una plataforma de cursos online con estudiantes, cursos, inscripciones, pagos, avances y reseñas.

## Contenido

| Archivo | Tema |
|---|---|
| `M2_L4_sqlplusdb_laroga.sql` | Creación y carga de la base, y recorrido de la teoría: subconsultas, `EXISTS`, CTE, funciones de ventana, pivoteo e índices |
| `M2_L4_practicas_laroga.sql` | Primeras pruebas de CTE recursiva (series de números) |
| `M2_L4_practica01_subconsultas_laroga.sql` | Subconsultas escalares, de conjunto y correlacionadas; `IN`, `LEFT JOIN` y `EXISTS` comparados |
| `M2_L4_practica02_ctes_laroga.sql` | CTE encadenadas y CTE recursiva (cadena de prerrequisitos) |
| `M2_L4_practica03_ventana_laroga.sql` | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD`, `FIRST_VALUE` y `LAST_VALUE` |
| `M2_L4_practica04_optimizacion_laroga.sql` | `LIMIT`, `DISTINCT`, pivoteo con `FILTER`, `EXPLAIN ANALYZE` e índices; corrección de una vista generada por IA |
| `M2_L4_practica05_cte_vs_subconsulta_laroga.sql` | La misma consulta resuelta con subconsulta y con CTE; jerarquía con CTE recursiva |

## Cómo ejecutarlo

1. Crear la base `sqlplusdb` y abrir un editor conectado a ella (en DBeaver: clic derecho sobre la base → *SQL Editor → New SQL script*).
2. Ejecutar `M2_L4_sqlplusdb_laroga.sql` completo: borra y vuelve a crear las tablas, así que se puede correr más de una vez.
3. Ejecutar las prácticas en orden. La **práctica 4 necesita la vista `vw_ultimo_progreso`**, que se crea en la práctica 3.

Verificación de la carga: students 10, courses 10, enrollments 8, payments 5, progress 4, reviews 4.

## Hallazgos en los datos

La base viene con datos sucios a propósito, y varios resultados se explican por eso:

- **Registros repetidos con otro formato:** los estudiantes y cursos 6 a 10 son copias de los primeros cinco con mayúsculas, espacios o tildes distintas (`'  marta  diaz'`, `'sql para Principiantes'`), más un registro `'N/A'`.
- **Inscripciones duplicadas:** Marta en el curso 1 y Luna en el curso 3 aparecen dos veces. Por eso algunos conteos salen inflados y se usa `COUNT(DISTINCT ...)` o `ROW_NUMBER` para detectarlas.
- **Reseña duplicada:** Marta tiene dos veces la misma reseña del curso 2.
- **Luna cursa Tableau sin haber pagado:** tiene inscripción, avance del 25 % y reseña, pero ningún pago.
- **Tomás completó un curso sin registro de avance** en `progress`.
- **Categorías inconsistentes** (`'BI'`, `'Business intelligence '` con espacio final): al agrupar forman categorías separadas.

## Decisiones

- **Adaptación a las columnas reales:** los scripts de la consigna usaban nombres que no existen en `sqlplusdb` (`active`, `progress`, `books`, `employees`). Se reescribieron con las columnas reales y cada archivo lo aclara en su encabezado.
- **Tablas inventadas con `VALUES`:** la base no tiene prerrequisitos ni empleados, así que para las CTE recursivas se arman dentro de la consulta.
- **Vista en lugar de CTE suelta:** una CTE vale solo para la sentencia en la que está escrita; `vw_ultimo_progreso` se guardó como vista para reutilizarla en otras consultas.
- **Pivoteo:** PostgreSQL no tiene `PIVOT` ni `UNPIVOT`; se usan `SUM(...) FILTER (WHERE ...)` y `CROSS JOIN LATERAL (VALUES ...)`.
- **`EXPLAIN ANALYZE` sigue mostrando `Seq Scan` después del índice:** con 8 filas recorrer la tabla es más rápido que usar el índice. En tablas grandes el plan cambia.
- **Vista generada por IA corregida:** la propuesta usaba tablas inexistentes y unía pagos, avances y reseñas a la vez, lo que multiplica las filas e infla las sumas. Se reemplazó por una vista que calcula cada métrica por separado y recién después las une.
- **Sin `BEGIN`/`COMMIT`:** DBeaver trabaja en modo Auto-commit.
