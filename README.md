# Módulo 2: SQL y bases de datos

Trabajos del Módulo 2 de la carrera de Data Science de Henry, organizados por lecture. Cada carpeta tiene sus scripts y un README con el contenido, cómo ejecutarlo y las decisiones tomadas.

## Herramientas

- **DBeaver** para escribir y ejecutar SQL.
- **PostgreSQL** como motor principal. Los tutoriales de las lectures 1 y 2 están en **SQL Server**.
- **Docker** para levantar los motores en la computadora.
- **VS Code** y **Git** para Python y control de versiones.

## Lectures

| Lecture | Tema | Contenido |
|---|---|---|
| [Lecture 1](M2_L1_Introduccion_bases_datos_y_DDL_laroga) | Introducción a las bases de datos y DDL | Creación de bases y tablas, claves y restricciones, y el mismo esquema en distintos motores (ver proyectos) |
| [Lecture 2](M2_L2_Sublenguaje_DML_laroga) | Sublenguaje DML | `INSERT`, `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `UPDATE`, `DELETE` y `ALTER TABLE` sobre CompanyDB y HealthTrackDB |
| [Lecture 3](M2_L3_Consultas_compuestas_GBD_laroga) | Consultas compuestas y gestión de bases de datos | `JOIN`, operaciones de conjuntos, indicadores RFM, índices, triggers, transacciones y vistas sobre VentasDB |
| [Lecture 4](M2_L4_Subconsultas_Funciones_ventana_laroga) | Subconsultas, CTE y funciones de ventana | Subconsultas, CTE recursivas, `ROW_NUMBER`, `RANK`, `LAG`, `LEAD`, `EXPLAIN ANALYZE` e índices sobre SQLPlusDB |

## Proyectos de la Lecture 1

Estos trabajos tienen su propio repositorio:

| Proyecto | Qué es |
|---|---|
| [FoodTrack](https://github.com/laroga007/foodtrack) | Esquema relacional de pedidos de foodtrucks en SQL Server, con su migración a PostgreSQL |
| [EduCursos](https://github.com/laroga007/educursos) | El mismo esquema en SQL Server, PostgreSQL, MySQL y SQLite, más una carga de datos con Python y SQLAlchemy que registra los errores |
| [Hospital_BD](https://github.com/laroga007/hospital_bd) | Migración de una base de datos de SQL Server a PostgreSQL, con las diferencias entre los dos motores |

En la carpeta de la Lecture 1 quedan además el script original de Hospital_BD en SQL Server (`M2_L1_hospital_bd_sqlserver_laroga.sql`) y el script de EduCursos tal como lo entrega el curso (`online_learning_platform_mssql.sql`).

## Convenciones

- Los archivos llevan el prefijo del módulo y la lecture (`M2_L3_...`) y terminan en `_laroga`.
- Cada script aclara en su encabezado en qué base se ejecuta y si fue adaptado de la consigna.
- Cuando la consigna tiene una inconsistencia, se resuelve y se explica en el script y en el README de la lecture.
