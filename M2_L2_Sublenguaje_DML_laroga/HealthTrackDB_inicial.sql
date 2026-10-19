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