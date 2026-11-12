# Módulo 2: SQL y bases de datos

<div align="justify">

Trabajos del Módulo 2 de la carrera de Data Science de Henry, organizados por lecture. Cada carpeta tiene sus scripts y un README con el contenido, cómo ejecutarlo y las decisiones tomadas.

## Herramientas

- **DBeaver** para escribir y ejecutar SQL.
- **PostgreSQL** como motor principal. Los tutoriales de las lectures 1 y 2 están en **SQL Server**.
- **Docker** para levantar los motores en la computadora y Kafka en la Lecture 8.
- **Snowflake** (interfaz web Snowsight) para el data warehouse en la nube de la Lecture 7.
- **MongoDB** (en Docker) y **MongoDB Compass** para las bases NoSQL de la Lecture 10.
- **VS Code** y **Git** para Python y control de versiones.

## Lectures

| Lecture | Tema | Contenido |
|---|---|---|
| [Lecture 1](M2_L1_Introduccion_bases_datos_y_DDL_laroga) | Introducción a las bases de datos y DDL | Creación de bases y tablas, claves y restricciones, y el mismo esquema en distintos motores (ver proyectos) |
| [Lecture 2](M2_L2_Sublenguaje_DML_laroga) | Sublenguaje DML | `INSERT`, `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `UPDATE`, `DELETE` y `ALTER TABLE` sobre CompanyDB y HealthTrackDB |
| [Lecture 3](M2_L3_Consultas_compuestas_GBD_laroga) | Consultas compuestas y gestión de bases de datos | `JOIN`, operaciones de conjuntos, indicadores RFM, índices, triggers, transacciones y vistas sobre VentasDB |
| [Lecture 4](M2_L4_Subconsultas_Funciones_ventana_laroga) | Subconsultas, CTE y funciones de ventana | Subconsultas, CTE recursivas, `ROW_NUMBER`, `RANK`, `LAG`, `LEAD`, `EXPLAIN ANALYZE` e índices sobre SQLPlusDB |
| [Lecture 5](M2_L5_Introduccion_al_modelado_de_datos_laroga) | Introducción al modelado de datos | Modelo estrella a partir de un dataset plano (RetailX), carga desde staging y homework de diseño dimensional (MusicFlow) |
| [Lecture 6](M2_L6_Modelado_avanzado_de_datos_laroga) | Modelado avanzado de datos | Tipos de tablas de hechos, métricas aditivas y derivadas, SCD Tipo 1, 2 y 3, mini-dimensión, dimensión degenerada, particionamiento y vistas materializadas (plataforma de delivery) |
| [Lecture 7](M2_L7_Data_warehousing_laroga) | Data warehousing en Snowflake | Warehouses, stages, `COPY INTO`, capas RAW y DW, enmascaramiento de datos, roles y permisos (RetailX), y homework TravelNow con una vista consultada desde Python |
| [Lecture 8](M2_L8_Arquitectura_de_datos_laroga) | Fundamentos de arquitectura de datos | Maqueta de la arquitectura de DataShop: ingesta en tiempo real con Kafka en Docker, detección de fraude, ETL batch de ventas diarias y automatización con Python |
| [Lecture 9](M2_L9_Arquitectura_en_la_nube_laroga) | Arquitectura en la nube con AWS | Diseño de la arquitectura de GreenSense (API Gateway, S3, Lambda, RDS, DynamoDB), maqueta local con validación, alertas y linaje en PostgreSQL, y estimación de costos en la AWS Pricing Calculator |
| [Lecture 10](M2_L10_Datos_no_estructurados_laroga) | Datos no estructurados y bases NoSQL | MongoDB con Compass: ejemplo de la lecture (asistente de conocimiento con índice de texto y búsqueda semántica con embeddings) y homework de tienda virtual (CRUD, índices, agregaciones e índice TTL) |

## Proyecto Integrador

El homework de cuatro lectures es un avance del Proyecto Integrador del módulo (FleetLogix), que está en su propio repositorio: [ProyectoM2_LauraGarmendia](https://github.com/laroga007/ProyectoM2_LauraGarmendia).

| Avance | Lecture |
|---|---|
| Avance 1 | [Lecture 4](M2_L4_Subconsultas_Funciones_ventana_laroga) |
| Avance 2 | [Lecture 6](M2_L6_Modelado_avanzado_de_datos_laroga) |
| Avance 3 | [Lecture 8](M2_L8_Arquitectura_de_datos_laroga) |
| Avance 4 | [Lecture 9](M2_L9_Arquitectura_en_la_nube_laroga) |

## Proyectos de la Lecture 1

Estos trabajos tienen su propio repositorio y están incluidos como submódulos dentro de la carpeta de la Lecture 1:

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

</div>
