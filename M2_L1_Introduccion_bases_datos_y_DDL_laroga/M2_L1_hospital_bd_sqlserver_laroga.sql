--CREACION DE BASE DE DASTOS Hospital_BD
CREATE DATABASE Hospital_BD;
GO

-- USO DE BASE DE DASTOS
USE Hospital_BD

--CREACION DE TABLAS

--Tabla de Especializaciones
CREATE TABLE Especializaciones(
    ID_Especializacion INT PRIMARY KEY IDENTITY (1,1),
    Nombre_Especializacion NVARCHAR(100) NOT NULL UNIQUE
);

--Tabla Medicos
CREATE TABLE Medicos (
    ID_Medico INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR(50) NOT NULL,
    Apellido NVARCHAR(50) NOT NULL,
    ID_Especializacion INT NOT NULL FOREIGN KEY REFERENCES Especializaciones(ID_Especializacion),
    UNIQUE (Nombre, Apellido)
);

--Tabla Emergencias
CREATE TABLE Emergencias (
    ID_Emergencia INT PRIMARY KEY IDENTITY (1,1),
    Fecha DATETIME NOT NULL,
    ID_Paciente INT,
    Descripcion NVARCHAR(255),
    Urgencia INT CHECK (Urgencia BETWEEN 1 AND 10)
);

--Tabla Pacientes
CREATE TABLE Pacientes (
    ID_Paciente INT PRIMARY KEY IDENTITY (1,1),
    Nombre NVARCHAR(100),
    Apellido NVARCHAR(100),
    Fecha_Nacimiento DATETIME
);

--Tabla Consultas
CREATE TABLE Consultas (
    ID_Consulta INT PRIMARY KEY IDENTITY (1,1),
    Fecha DATETIME NOT NULL,
    ID_Paciente INT,
    ID_Medico INT NOT NULL FOREIGN KEY REFERENCES Medicos(ID_Medico),
    Descripcion NVARCHAR(255)
);

--Tabla Internaciones
CREATE TABLE Internaciones (
    ID_Internacion INT PRIMARY KEY IDENTITY (1,1),
    ID_Paciente INT FOREIGN KEY REFERENCES Pacientes(ID_Paciente),
    ID_Medico INT FOREIGN KEY REFERENCES Medicos(ID_Medico),
    Fecha_Inicio DATETIME NOT NULL,
    Fecha_Fin DATETIME NOT NULL,
    Habitacion NVARCHAR(50)
);

--INSERCION DE DATOS EN TABLAS

--Insertar datos en las Especializaciones
INSERT INTO Especializaciones(Nombre_Especializacion)VALUES
('Cardiología'),
('Neurología'),
('Pediatría'),
('Ginecología'),
('Traumatología'),
('Oncología'),
('Dermatología'),
('Psiquiatría'),
('Oftalmología'),
('Anestesiología'),
('Ortopedia'),
('Urología'),
('Endocrinología'),
('Gastroenterología'),
('Medicina General');

--Insertar datos de Nedicos

INSERT INTO Medicos (Nombre, Apellido, ID_Especializacion)VALUES
('Juan', 'Pérez', 1),
('Ana', 'Martínez', 2),
('Carlos', 'Gómez', 3),
('Laura', 'Rodríguez', 4),
('José', 'López', 5),
('María', 'García', 6),
('Carmen', 'Díaz', 7),
('Fernando', 'Moreno', 8),
('Elena', 'Jiménez', 9),
('Roberto', 'Alonso', 10),
('Sofía', 'Ruíz', 11),
('Ricardo', 'Sánchez', 12),
('Patricia', 'Torres', 13),
('Luis', 'Dominguez', 14),
('Sandra', 'Ortiz', 15);

--Insertar datos de Pacientes
INSERT INTO Pacientes (Nombre, Apellido, Fecha_Nacimiento)VALUES
('Miguel', 'Hernández', '1980-02-15'),
('Lucía', 'Fernández', '1993-07-21'),
('Antonio', 'Ramirez', '1975-05-30'),
('Diana', 'Castro', '1988-11-12'),
('Alejandro', 'Morales', '1990-01-09'),
('Sofía', 'Ruíz', '2000-03-03'),
('Carlos', 'Vega', '1995-06-07'),
('María', 'Marínez', '1983-08-20'),
('Eduardo', 'López', '1968-09-15'),
('Ana', 'García', '1972-04-26'),
('Raquel', 'González', '2001-12-30'),
('Jorge', 'Pérez', '1985-10-05'),
('Carmen', 'Sánchez', '1999-02-19'),
('Pablo', 'Moreno', '2002-07-13'),
('Beatriz', 'Jiménez', '1978-03-22');

--Insetar datos de Consultas
INSERT INTO Consultas (Fecha, ID_Paciente, ID_Medico, Descripcion)VALUES
('2024-01-10 09:00', 101, 1, 'Consulta de rutina'),
('2024-01-11 10:00', 102, 2, 'Revisión neurológica'),
('2024-01-12 08:30', 103, 3, 'Control pediátrico'),
('2024-01-13 09:00', 104, 4, 'Consulta ginecológica'),
('2024-01-14 10:30', 105, 5, 'Revisión de lesión deportiva'),
('2024-01-15 11:00', 106, 6, 'Consulta oncológica seguimiento'),
('2024-01-16 08:45', 107, 7, 'Revisión dermatológica'),
('2024-01-17 09:15', 108, 8, 'Consulta psiquiátrica'),
('2024-01-18 10:00', 109, 9, 'Control oftalmológico'),
('2024-01-19 11:30', 110, 10, 'Preparación para cirugía'),
('2024-01-20 08:20', 111, 11, 'Revisión ortopédica'),
('2024-01-21 09:40', 112, 12, 'Consulta urológica'),
('2024-01-22 10:10', 113, 13, 'Control endocrinológico'),
('2024-01-23 11:05', 114, 14, 'Revisión gastrointestinal'),
('2024-01-24 08:55', 115, 15, 'Chequeo médico general'),
('2024-01-25 09:30', 116, 1, 'Seguimiento cardiológico'),
('2024-01-26 10:20', 117, 2, 'Evaluación neurológica');

--Insertar datos en Emergencias
INSERT INTO Emergencias (Fecha, ID_Paciente, Descripcion, Urgencia)VALUES
('2024-01-15 23:00', 201, 'Dolor torácico', 5),
('2024-01-16 01:30', 202, 'Accidente vehicular', 9);

--Insertar datos en Internaciones
INSERT INTO Internaciones (ID_Paciente, ID_Medico, Fecha_Inicio, Fecha_Fin, Habitacion) VALUES
(1, 1, '2024-01-20 08:00', '2024-01-25', 'H101'),
(2, 2, '2024-01-22 09:00', '2024-01-30', 'H102'),
(3, 2, '2024-02-01 14:00', '2024-02-10', 'H203'),
(4, 3, '2024-02-05 15:00', '2024-02-12', 'H204');

SELECT * FROM Especializaciones;
SELECT * FROM Medicos;
SELECT * FROM Pacientes;
SELECT * FROM Consultas;
SELECT * FROM Emergencias;
SELECT * FROM Internaciones;

ALTER TABLE Pacientes ALTER COLUMN Fecha_Nacimiento DATE;

ALTER TABLE Medicos ADD Email NVARCHAR(100);

TRUNCATE TABLE Consultas

DROP TABLE Emergencias

INSERT INTO Consultas (Fecha, ID_Paciente, ID_Medico, Descripcion)VALUES
('2024-01-10 09:00', 101, 1, 'Consulta de rutina'),
('2024-01-11 10:00', 102, 2, 'Revisión neurológica'),
('2024-01-12 08:30', 103, 3, 'Control pediátrico'),
('2024-01-13 09:00', 104, 4, 'Consulta ginecológica'),
('2024-01-14 10:30', 105, 5, 'Revisión de lesión deportiva'),
('2024-01-15 11:00', 106, 6, 'Consulta oncológica seguimiento'),
('2024-01-16 08:45', 107, 7, 'Revisión dermatológica'),
('2024-01-17 09:15', 108, 8, 'Consulta psiquiátrica'),
('2024-01-18 10:00', 109, 9, 'Control oftalmológico'),
('2024-01-19 11:30', 110, 10, 'Preparación para cirugía'),
('2024-01-20 08:20', 111, 11, 'Revisión ortopédica'),
('2024-01-21 09:40', 112, 12, 'Consulta urológica'),
('2024-01-22 10:10', 113, 13, 'Control endocrinológico'),
('2024-01-23 11:05', 114, 14, 'Revisión gastrointestinal'),
('2024-01-24 08:55', 115, 15, 'Chequeo médico general'),
('2024-01-25 09:30', 116, 1, 'Seguimiento cardiológico'),
('2024-01-26 10:20', 117, 2, 'Evaluación neurológica');

--Tabla Emergencias
CREATE TABLE Emergencias (
    ID_Emergencia INT PRIMARY KEY IDENTITY (1,1),
    Fecha DATETIME NOT NULL,
    ID_Paciente INT,
    Descripcion NVARCHAR(255),
    Urgencia INT CHECK (Urgencia BETWEEN 1 AND 10)
);

INSERT INTO Emergencias (Fecha, ID_Paciente, Descripcion, Urgencia)VALUES
('2024-01-15 23:00', 201, 'Dolor torácico', 5),
('2024-01-16 01:30', 202, 'Accidente vehicular', 9);