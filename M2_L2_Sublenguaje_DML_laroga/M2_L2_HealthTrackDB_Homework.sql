-- Base de Datos: HealthTrackDB

-- Eliminamos tablas si existen
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;

-- Tabla: patients
CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date DATE,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20)
);

-- Tabla: doctors
CREATE TABLE doctors (
    doctor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    specialty VARCHAR(100),
    is_active BOOLEAN DEFAULT true
);

-- Tabla: appointments
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id INT REFERENCES patients(patient_id),
    doctor_id INT REFERENCES doctors(doctor_id),
    appointment_date DATE,
    notes TEXT
);

-- Inserción de datos ficticios
INSERT INTO patients (first_name, last_name, birth_date, email, phone) VALUES
('Laura', 'Pérez', '1988-03-22', 'laura.perez@email.com', '123456789'),
('Carlos', 'Ruiz', '1975-11-15', 'carlos.ruiz@email.com', '987654321'),
('María', 'Gómez', '1990-06-05', 'maria.gomez@email.com', '456789123');

INSERT INTO doctors (first_name, last_name, specialty, is_active) VALUES
('Ana', 'González', 'Cardiología', true),
('Luis', 'Fernández', 'Dermatología', false),
('Sofía', 'Martínez', 'Pediatría', true);

INSERT INTO appointments (patient_id, doctor_id, appointment_date, notes) VALUES
(1, 1, '2025-08-10', NULL),
(2, 3, '2025-08-12', 'Paciente con fiebre leve'),
(3, 1, '2025-08-05', NULL);

SELECT * FROM patients;
SELECT * FROM doctors;
SELECT * FROM appointments;

-- Nuevos pacientes (serán el 4 y el 5)
INSERT INTO patients (first_name, last_name, birth_date, email, phone) VALUES
('Jorge', 'Sosa', '1982-09-14', 'jorge.sosa@email.com', '1122334455'),
('Valeria', 'Díaz', '1995-01-30', 'valeria.diaz@email.com', '1166778899');

-- Nuevo médico activo (será el 4)
INSERT INTO doctors (first_name, last_name, specialty, is_active) VALUES
('Martín', 'López', 'Traumatología', true);

-- Nuevos turnos
INSERT INTO appointments (patient_id, doctor_id, appointment_date, notes) VALUES
(4, 4, '2026-10-02', 'Control post esguince de tobillo'),
(5, 3, '2026-11-20', NULL);

SELECT * FROM appointments;

-- Operador de comparación: pacientes nacidos después de 1985
SELECT first_name, last_name, birth_date
FROM patients
WHERE birth_date > '1985-01-01';

-- Operador lógico: médicos activos que no son de Cardiología
SELECT first_name, last_name, specialty, is_active
FROM doctors
WHERE is_active = true
  AND specialty <> 'Cardiología';

-- Valores nulos: turnos sin notas médicas
SELECT appointment_id, patient_id, doctor_id, appointment_date, notes
FROM appointments
WHERE notes IS NULL;

-- Extra 1: UPDATE - actualizar el teléfono de Carlos Ruiz
-- Antes
SELECT patient_id, first_name, last_name, phone
FROM patients
WHERE patient_id = 2;

-- Cambio
UPDATE patients
SET phone = '1144556677'
WHERE patient_id = 2;

-- Después
SELECT patient_id, first_name, last_name, phone
FROM patients
WHERE patient_id = 2;

-- Extra 2: DELETE - eliminar turnos con fecha posterior a hoy
-- Antes: qué se va a borrar
SELECT appointment_id, patient_id, doctor_id, appointment_date
FROM appointments
WHERE appointment_date > CURRENT_DATE;

-- Borrado
DELETE FROM appointments
WHERE appointment_date > CURRENT_DATE;

-- Después: tabla completa
SELECT * FROM appointments;

-- Extra 3: ALTER TABLE - la fecha del turno pasa a ser obligatoria
-- Antes: verificar que no haya fechas nulas (debe dar 0)
SELECT COUNT(*) AS fechas_nulas
FROM appointments
WHERE appointment_date IS NULL;

-- Cambio de estructura
ALTER TABLE appointments
ALTER COLUMN appointment_date SET NOT NULL;

-- Prueba: insertar un turno sin fecha (DEBE dar error)
INSERT INTO appointments (patient_id, doctor_id, notes)
VALUES (1, 1, 'Prueba sin fecha');

-- Extra 4: query generada por IA (Claude)
-- Pedido: nombre, apellido y edad actual de cada paciente, del más joven al más grande.
-- Análisis: el pedido no aclaraba el motor, así que la IA dio tres alternativas
-- (MySQL, SQL Server y PostgreSQL). Uso la de PostgreSQL, que es la que corresponde.
-- Validación: AGE() tiene en cuenta si la persona ya cumplió años este año,
-- y ORDER BY birth_date DESC ordena del más joven al más grande.
SELECT
    first_name AS nombre,
    last_name  AS apellido,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::int AS edad
FROM patients
ORDER BY birth_date DESC;

