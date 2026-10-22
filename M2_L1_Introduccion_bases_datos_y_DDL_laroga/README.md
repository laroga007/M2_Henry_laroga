# Lecture 1: introducción a las bases de datos y DDL

Práctica del Módulo 2 (SQL) de Henry Data Science, en DBeaver. Se trabaja con la creación de bases y tablas, los tipos de datos, las claves primarias y foráneas y las restricciones (`UNIQUE`, `CHECK`, `NOT NULL`), y con las diferencias entre motores SQL.

## Proyectos

Los trabajos de esta lecture tienen su propio repositorio:

| Proyecto | Motor | Qué es |
|---|---|---|
| [FoodTrack](https://github.com/laroga007/foodtrack) | SQL Server y PostgreSQL | Homework: esquema relacional de pedidos de foodtrucks, con diagrama ER, validaciones, evolución del esquema y migración a PostgreSQL |
| [EduCursos](https://github.com/laroga007/educursos) | SQL Server, PostgreSQL, MySQL y SQLite | El mismo esquema escrito en cuatro motores, una rama por motor, más una carga de datos con Python y SQLAlchemy que valida cada registro y guarda los rechazados en una tabla de errores |
| [Hospital_BD](https://github.com/laroga007/hospital_bd) | SQL Server y PostgreSQL | Migración de una base de datos de un motor a otro, documentando cada diferencia y los problemas encontrados en los datos |

## Archivos de esta carpeta

| Archivo | Qué es |
|---|---|
| `M2_L1_hospital_bd_sqlserver_laroga.sql` | Script original de Hospital_BD en SQL Server, a partir del cual se hizo la migración |
| `online_learning_platform_mssql.sql` | Script de EduCursos tal como lo entrega el curso, generado por un conversor automático. Es el punto de partida que se corrigió en el repo de EduCursos |

## Qué se aprendió

- **El orden de creación importa:** primero las tablas de las que dependen otras, después las que tienen claves foráneas hacia ellas.
- **Cada motor tiene su dialecto:** los tipos de texto, el autoincremento, la forma de cambiar de base y la escritura de las claves foráneas cambian entre SQL Server, PostgreSQL, MySQL y SQLite.
- **Las restricciones protegen los datos:** un `INSERT` con un dato inválido se rechaza completo, y eso permite detectar errores en el origen.
- **Un script guardado es la receta de la base:** la base es el resultado, pero sin el script no se puede repetir, corregir ni explicar cómo se llegó a ella.
