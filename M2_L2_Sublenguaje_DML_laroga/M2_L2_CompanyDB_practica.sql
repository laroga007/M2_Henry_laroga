/*
 * Consigna:
 * Supongamos que queremos analizar la distribucion de los empleados en terminos
 * de su antiguedad en la empresa y su ubicacion geografica. Especificamente, nos
 * gustaria saber:
 * En que anios y en que paises se contrataron mas empleados?
 * Esta informacion no ayudara a entender las tendencias de contratacion en
 * diferentes ubicaciones a lo largo del tiempo.
 * Comencemos por crear la BD y las tablas:
 */

-- Crear la base de datos
CREATE DATABASE CompanyDB;

-- Comando de uso de la base de datos creada
USE CompanyDB;

-- Crear la tabla Employees
CREATE TABLE Employees(
	EmployeeID INT PRIMARY KEY,
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	Country NVARCHAR(50),
	HireDate DATE
);

-- Crear la tabla Salaries
CREATE TABLE Salaries(
	EmployeeID INT PRIMARY KEY,
	Salary DECIMAL(10,2),
	FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID)
);

-- Crear tabla de Categories
CREATE TABLE Categories(
	CategoryID INT PRIMARY KEY,
	CategoryName NVARCHAR(50)
);

/*
 * Una vez que realizaste esto, estas preparado para comenzar a trabajar con las clausulas descritas
 * Vamos a insertar datos en las tablas creadas. Para esto utilizaremos la clausula INSERT.
 * Si quisieramos insertar solo una fila de datos lo hariamos de la siguiente manera:
 */

-- Insertamos una fila de datos a la tabla Employees
INSERT INTO Employees (EmployeeID, FirstName, LastName, Country, HireDate)
VALUES (1, 'John', 'Doe', 'USA', '2013-01-08');

-- insertamos varias filas de datos a la tabla Employees
INSERT INTO Employees (EmployeeID, FirstName, LastName, Country, HireDate)VALUES
(2, 'Anna', 'Smith', 'UK', '2015-06-12'),
(3, 'David', 'Wilson', 'USA', '2014-03-05'),
(4, 'Sarah', 'Brown', 'UK', '2017-11-11'),
(5, 'Michael', 'Davis', 'USA', '2016-02-09'),
(6, 'Emily', 'Clark', 'USA', '2014-07-22'),
(7, 'Liam', 'Johnson', 'Canada', '2014-05-30'),
(8, 'Oliver', 'Martinez', 'UK', '2016-12-01'),
(9, 'Sophia', 'Lopez', 'USA', '2015-03-15'),
(10, 'Isabella', 'Garcia', 'Canada', '2017-08-24'),
(11, 'Ethan', 'Harris', 'USA', '2014-11-09'),
(12, 'Mia', 'Sanchez', 'USA', '2016-04-17'),
(13, 'Lucas', 'Robinson', 'Canada', '2015-07-05'),
(14, 'Amelia', 'Gonzalez', 'UK', '2014-02-20'),
(15, 'Noah', 'Anderson', 'UK', '2015-09-13');

--Insertamos datos de la tabla Salaries
INSERT INTO Salaries (EmployeeID,Salary)VALUES
(1, 50000.00),
(2, 55000.00),
(3, 52000.00),
(4, 60000.00),
(5, 58000.00),
(6, 47000.00),
(7, 63000.00),
(8, 54000.00),
(9, 50000.00),
(10, 56000.00);

-- Insertamos datos a la tabla Categories
INSERT INTO Categories (CategoryID, CategoryName)VALUES
(1, 'IT'),
(2, 'Human Resources'),
(3, 'Marketing'),
(4, 'Sales'),
(5, 'Finance'),
(6, 'Development'),
(7, 'Research'),
(8, 'Customer Service'),
(9, 'Quality Assurance'),
(10, 'Product Management');

SELECT * FROM Employees;
SELECT * FROM Salaries;
SELECT * FROM Categories;

/*
Seleccionar el pais y el anio de contratacion de los empleados.
Contar el numero total de empleados contratados por pais por anio.
Filtrar para incluir solo aquellos anios y paises donde se contrataron mas de dos empleados desde el anio 2014
Ordenar los resultados por anio de contratacion de manera descendente.
*/

-- Comandos basicos
/*
SELECT: selecciona columnas.
FROM: especifica la tabla de donde se extraen los datos.
WHERE: filtra para considerar solo aquellos empleados contratados desde el 1 de enero de 2014
 */

-- Comandos adicionales
/*
GROUP BY: agrupa los resultados por las columnas definidas.
Esto es necesario al realizar una funcion de agregacion que requiere una apertura de campos
HAVING: filtra los grupos de filas.
ORDER BY: ordena los resultados
*/

SELECT 
	Country, 
	YEAR(HireDate) AS YearHired, 
	COUNT(*) AS NumEmployees
FROM 
	Employees
WHERE 
	HireDate >= '2014-01-01'
GROUP BY 
	Country, YEAR(HireDate)
HAVING 
	COUNT(*) > 2
ORDER BY 
	YearHired DESC;

