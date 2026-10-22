   SELECT current_database();
   
   -- Base de Datos: SQLPlusDB

-- Eliminación previa
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS progress;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS students;

-- Tabla: students
CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    registration_date DATE
);

-- Tabla: courses
CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

-- Tabla: enrollments
CREATE TABLE enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    enrollment_date DATE,
    completed BOOLEAN
);

-- Tabla: payments
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    amount_paid DECIMAL(10,2),
    payment_date DATE
);

-- Tabla: progress
CREATE TABLE progress (
    progress_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    last_access_date DATE,
    percentage_completed DECIMAL(5,2)
);

-- Tabla: reviews
CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id),
    course_id INT REFERENCES courses(course_id),
    rating INT,
    comment TEXT,
    review_date DATE
);

-- Datos de ejemplo
INSERT INTO students (full_name, email, registration_date) VALUES
('Marta Díaz', 'marta.diaz@email.com', '2023-01-10'),
('Tomás Pérez', 'tomas.perez@email.com', '2023-02-01'),
('Luna Salas', 'luna.salas@email.com', '2023-03-05'),
('Diego Ruiz', 'diego.ruiz@email.com', '2023-03-15'),
('María José', 'maria.jose@email.com', '2023-03-18'),
('  marta  diaz', 'marta.diaz @email.com', '2023-01-10'),
('Tomas  PEREZ', 'tomas.perez@emailcom', '2023-02-01'),
('Luna  Salás', ' luna.salas@email.com', '2023-03-05'),
('N/A', 'NULL', '2023-03-20'),
('MAriA   JOse', 'MARIA.JOSE@email.COM ', '2023-03-18');

INSERT INTO courses (course_name, category, price) VALUES
('SQL para principiantes', 'Bases de Datos', 50.00),
('Data Science con Python', 'Ciencia de Datos', 120.00),
('Visualización con Tableau', 'Business Intelligence', 80.00),
('SQL Avanzado', 'Bases de Datos', 90.00),
('Power BI para Negocios', 'Business Intelligence', 100.00),
('sql para Principiantes', 'bases de datos', 50.00),
('Data Science c/ Python', 'ciencia de datos', 120.00),
('Visualizacion con tableau', 'Business intelligence ', 80.00),
('N/A', 'NULL', 0.00),
('PowerBI negocios', 'BI', 100.00);

INSERT INTO enrollments (student_id, course_id, enrollment_date, completed) VALUES
(1, 1, '2023-01-15', true),
(1, 2, '2023-02-10', false),
(2, 1, '2023-02-05', true),
(3, 3, '2023-03-10', false),
(4, 4, '2023-03-20', false),
(5, 5, '2023-03-22', false),
(1, 1, '2023-01-15', true),
(3, 3, '2023-03-10', false);

INSERT INTO payments (student_id, course_id, amount_paid, payment_date) VALUES
(1, 1, 50.00, '2023-01-15'),
(1, 2, 120.00, '2023-02-10'),
(2, 1, 50.00, '2023-02-05'),
(4, 4, 90.00, '2023-03-20'),
(5, 5, 100.00, '2023-03-22');

INSERT INTO progress (student_id, course_id, last_access_date, percentage_completed) VALUES
(1, 2, '2023-02-20', 40.00),
(3, 3, '2023-03-20', 25.00),
(4, 4, '2023-03-25', 10.00),
(5, 5, '2023-03-28', 5.00);

INSERT INTO reviews (student_id, course_id, rating, comment, review_date) VALUES
(1, 2, 5, 'Muy completo.', '2023-02-25'),
(3, 3, 4, 'Me gustó el enfoque.', '2023-03-22'),
(1, 2, 5, 'Muy completo.', '2023-02-25'),
(2, 1, 5, 'Excelente base.', '2023-02-07');

SELECT 'students' AS tabla, COUNT(*) FROM students
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'enrollments', COUNT(*) FROM enrollments
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'progress', COUNT(*) FROM progress
UNION ALL SELECT 'reviews', COUNT(*) FROM reviews;


-- Calculo de promedio
SELECT AVG(price) FROM courses;

-- Devuelve cursos mas caros que el curso promedio
-- Resuelve primero lo de adentro, que da un número, y después filtra con ese número.
SELECT course_id, course_name, price
FROM courses
WHERE price > (SELECT AVG(price) FROM courses);

-- La subconsulta también puede ir en el SELECT
-- Acá el promedio aparece repetido en cada fila, como una columna más
SELECT course_name,
       price,
       (SELECT AVG(price) FROM courses) AS promedio,
       price - (SELECT AVG(price) FROM courses) AS diferencia
FROM courses;

-- Consulta que muestre los pagos (payments) 
-- cuyo amount_paid sea mayor al promedio de todos los pagos
SELECT payment_id, course_id, amount_paid
FROM payments
WHERE amount_paid > (SELECT AVG (amount_paid) FROM payments);

-- Devuelve estudiantes que completaron al menos un curso
-- Utilizando a la subconsulta que resuelve la lógica: quiénes completaron algo.
-- La consulta de afuera solo pregunta qué estudiantes están en esa lista.
SELECT student_id, full_name
FROM students
WHERE student_id IN (SELECT student_id
                     FROM enrollments
                     WHERE completed = true);

-- Subconsulta de conjunto:
-- estudiantes que tienen al menos una inscripción
SELECT student_id, full_name
FROM students
WHERE student_id IN (SELECT student_id FROM enrollments);

-- estudiantes que no tienen ninguna inscripción
SELECT student_id, full_name
FROM students
WHERE student_id NOT IN (SELECT student_id FROM enrollments);

-- cursos que nunca recibieron un pago
SELECT  course_id, course_name
FROM courses
WHERE course_id NOT IN (SELECT course_id FROM payments);

SELECT * FROM enrollments WHERE course_id = 3;
-- Hallazgo: Luna (student_id 3) tiene inscripción duplicada en el curso 3
-- (enrollment_id 4 y 8), avance de 25 % y reseña, pero ningún pago registrado

-- Subconsulta correlacionada
-- cada estudiante con su cantidad de inscripciones
SELECT s.student_id,
       s.full_name,
       (SELECT COUNT(*)
        FROM enrollments e
        WHERE e.student_id = s.student_id) AS inscripciones
FROM students s;

-- Cada curso con su cantidad de resenias
SELECT 	c.course_id,
		c.course_name,
		(SELECT COUNT (*)
		FROM reviews r 
		WHERE r.course_id = c.course_id) AS resenias
FROM courses c;

-- EXISTS
-- estudiantes que hicieron al menos un pago
SELECT s.student_id, s.full_name
FROM students s
WHERE EXISTS (SELECT 1
              FROM payments p
              WHERE p.student_id = s.student_id);

-- estudiantes que no dejaron ninguna reseña
SELECT s.student_id, s.full_name
FROM students s
WHERE NOT EXISTS (SELECT 1
				  FROM reviews r 
				  WHERE r.student_id = s.student_id);

-- CTE (Common Table Expression)
-- total pagado por cada estudiante
WITH pagos_por_estudiante AS (
    SELECT student_id, SUM(amount_paid) AS total_pagado
    FROM payments
    GROUP BY student_id
)
SELECT s.full_name, p.total_pagado
FROM pagos_por_estudiante p
JOIN students s ON s.student_id = p.student_id;

-- la misma CTE, reutilizada. Estudiantes que pagaron más que el promedio de lo pagado por estudiante
WITH pagos_por_estudiante AS (
    SELECT student_id, SUM(amount_paid) AS total_pagado
    FROM payments
    GROUP BY student_id
)
SELECT s.full_name, p.total_pagado
FROM pagos_por_estudiante p
JOIN students s ON s.student_id = p.student_id
WHERE p.total_pagado > (SELECT AVG(total_pagado) FROM pagos_por_estudiante);

-- cuenta las inscripciones de cada curso (course_id y la cantidad)
WITH inscripciones_por_curso AS (
	 SELECT course_id, COUNT(*) AS total_inscriptos
	 FROM enrollments
	 GROUP BY course_id
)
SELECT c.course_name, i.total_inscriptos
FROM inscripciones_por_curso i
JOIN courses c ON c.course_id = i.course_id;

-- cuenta las inscripciones por cada curso y devuelve donde hay mas de una
WITH inscripciones_por_curso AS (
	 SELECT course_id, COUNT(*) AS total_inscriptos
	 FROM enrollments
	 GROUP BY course_id
)
SELECT c.course_name, i.total_inscriptos
FROM inscripciones_por_curso i
JOIN courses c ON c.course_id = i.course_id
WHERE i.total_inscriptos > 1;

-- Cambiando COUNT(*) por COUNT(DISTINCT student_id) para que no cuente duplicados
-- ahora cuenta estudiantes no filas.
WITH inscripciones_por_curso AS (
	 SELECT course_id, COUNT(DISTINCT student_id) AS total_inscriptos
	 FROM enrollments
	 GROUP BY course_id
)
SELECT c.course_name, i.total_inscriptos
FROM inscripciones_por_curso i
JOIN courses c ON c.course_id = i.course_id
WHERE i.total_inscriptos > 1;

-- FUNCIONES VENTANA
-- numera las inscripciones de cada estudiante por separado (PARTITION BY),
-- de la más vieja a la más nueva (ORDER BY)
SELECT student_id,
       course_id,
       enrollment_date,
       ROW_NUMBER() OVER (PARTITION BY student_id
                          ORDER BY enrollment_date, enrollment_id) AS nro_inscripcion
FROM enrollments;

--ROW_NUMBER se utiliza para numerar y detectar duplicados tambien
-- aca salen las filas 7 y 8 con nro=2 por lo que son duplicados
SELECT enrollment_id, student_id, course_id,
       ROW_NUMBER() OVER (PARTITION BY student_id, course_id
                          ORDER BY enrollment_id) AS nro
FROM enrollments;

-- RANK arma un ranking (si empata comparten puesto y saltea el siguiente)
-- cursos por precio
SELECT course_name, price,
       RANK() OVER (ORDER BY price DESC) AS puesto
FROM courses;

-- DENSE_RANK arma ranking tambien, pero no saltea puestos
SELECT course_name, price,
       DENSE_RANK() OVER (ORDER BY price DESC) AS puesto
FROM courses;

-- LAG trae el valor de la fila anterior, segun el orden indicado, se usa para comparar
-- en la primera fila devuelve NULL
SELECT payment_id, payment_date, amount_paid,
       LAG(amount_paid) OVER (ORDER BY payment_date) AS pago_anterior
FROM payments;

-- LEAD lo opuesto a LAG, trae el valor de la fila siguiente, y es NULL en la ultima
SELECT payment_id, payment_date,
       LEAD(payment_date) OVER (ORDER BY payment_date) AS proximo_pago
FROM payments;

-- FIRST_VALUE
-- el primer curso que pago cada estudiante
SELECT student_id, course_id, payment_date,
       FIRST_VALUE(course_id) OVER (PARTITION BY student_id
                                    ORDER BY payment_date) AS primer_curso
FROM payments;

-- LAST_VALUE trae el ultimo valor de cada grupo
-- por defecto muestra la fila actual, sin aclaracion devuelve el valor de su propia fila
-- hay que aclararle que mire todo el grupo completo:
-- ROWS BETWEEN UNBOUNDED PREDECING AND UNBOUNDED FOLLOWING
-- el último curso que pagó cada estudiante
SELECT student_id, course_id, payment_date,
       LAST_VALUE(course_id) OVER (PARTITION BY student_id ORDER BY payment_date
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS ultimo_curso
FROM payments;

-- Extra: acumulado con SUM (acumulado progresivo)
-- devuelve cada pago con el total recaudado hasta la fecha
SELECT payment_date, amount_paid,
       SUM(amount_paid) OVER (ORDER BY payment_date) AS acumulado
FROM payments;

-- Optimización
-- LIMIT devuelve solo las primeras N filas, va con ORDER BY, sino son "al azar"
-- los tres cursos mas caros:
SELECT course_name, price
FROM courses
ORDER BY price DESC
LIMIT 3;

-- DISTINCT elimina las filas repetidas del resultado, la tabla no se modifica
-- combinaciones únicas de estudiante y curso
SELECT DISTINCT student_id, course_id
FROM enrollments;

-- Pivotear (en lugar de PIVOT)
-- lo pagado por cada estudiante, por mes
SELECT student_id,
       SUM(amount_paid) FILTER (WHERE EXTRACT(MONTH FROM payment_date) = 1) AS enero,
       SUM(amount_paid) FILTER (WHERE EXTRACT(MONTH FROM payment_date) = 2) AS febrero,
       SUM(amount_paid) FILTER (WHERE EXTRACT(MONTH FROM payment_date) = 3) AS marzo
FROM payments
GROUP BY student_id;

-- Despivotear (en lugar de UNPIVOT)
-- convierte columnas en filas
-- en Postgress se hace con CROSS JOIN LATERAL y VALUES
-- precio del curso y monto pagado como filas:
SELECT p.payment_id, v.concepto, v.valor
FROM payments p
JOIN courses c ON c.course_id = p.course_id
CROSS JOIN LATERAL (VALUES ('precio', c.price),
                           ('pagado', p.amount_paid)) AS v(concepto, valor);

-- Indices: como el índice de un libro: PostgreSQL encuentra filas sin recorrer toda la tabla
CREATE INDEX idx_enrollments_student ON enrollments(student_id);

-- EXPLAIN ANALYZE
-- la consulta y muestra cómo la resolvió PostgreSQL:
-- si recorrió toda la tabla (Seq Scan) o usó un índice (Index Scan), y cuánto tardó (Execution Time)
EXPLAIN ANALYZE
SELECT * FROM enrollments WHERE student_id = 1;

