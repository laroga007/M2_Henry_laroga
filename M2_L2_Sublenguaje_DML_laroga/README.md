# Lecture 2: sublenguaje DML

Práctica del Módulo 2 (SQL) de Henry Data Science, en DBeaver. Se trabaja con las cláusulas para cargar, consultar, modificar y borrar datos: `INSERT`, `SELECT`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`, `UPDATE`, `DELETE` y `ALTER TABLE`.

## Contenido

| Archivo | Motor | Tema |
|---|---|---|
| `M2_L2_CompanyDB_practica.sql` | SQL Server | Tutorial de la lecture: creación de `CompanyDB`, carga de datos y consulta agrupada |
| `HealthTrackDB_inicial.sql` | PostgreSQL | Script base del homework, tal como lo entrega el curso |
| `M2_L2_HealthTrackDB_Homework.sql` | PostgreSQL | Homework: el script base más los registros nuevos, las consultas y los ejercicios extra |

## CompanyDB: tendencias de contratación

**Consigna:** en qué años y en qué países se contrataron más empleados.

La consulta toma las contrataciones desde 2014, las agrupa por país y año (`GROUP BY`), deja solo los grupos con más de dos empleados (`HAVING`) y ordena por año de forma descendente.

**Resultado:** USA en 2014, con 3 contrataciones. Es el único grupo que supera los dos empleados.

## HealthTrackDB: homework

Base de una clínica con pacientes, médicos y turnos.

| Parte | Qué se hace |
|---|---|
| Carga | Dos pacientes nuevos, un médico activo nuevo y dos turnos |
| Operador de comparación | Pacientes nacidos después de 1985 |
| Operador lógico | Médicos activos que no son de Cardiología |
| Valores nulos | Turnos sin notas médicas (`IS NULL`) |
| Extra 1: `UPDATE` | Cambio del teléfono de un paciente, con consulta antes y después |
| Extra 2: `DELETE` | Borrado de los turnos con fecha posterior a hoy, revisando antes qué se va a borrar |
| Extra 3: `ALTER TABLE` | La fecha del turno pasa a ser obligatoria (`NOT NULL`) y se prueba que rechace un turno sin fecha |
| Extra 4: consulta generada por IA | Edad actual de cada paciente con `AGE()`, revisada y validada |

## Cómo ejecutarlo

**CompanyDB (SQL Server):** ejecutar el script completo. Antes de las consultas, verificar en la barra de DBeaver que la base activa sea `CompanyDB` y no `master`.

**HealthTrackDB (PostgreSQL):** crear la base `healthtrackdb`, abrir un editor conectado a ella y ejecutar el homework **por bloques**, en orden. El script empieza con `DROP TABLE IF EXISTS`, así que se puede volver a correr desde cero.

No conviene ejecutarlo completo de una vez: la prueba del Extra 3 inserta un turno sin fecha **a propósito para que dé error**, y ese error corta la ejecución.

## Decisiones

- **Motor:** el tutorial de la lecture está en SQL Server (`NVARCHAR`, `USE`, `YEAR()`) y se respetó así. El homework está en PostgreSQL, el motor de las clases en vivo.
- **Mirar antes de modificar:** cada `UPDATE` y `DELETE` va precedido de un `SELECT` con la misma condición, para ver qué filas se van a tocar antes de cambiarlas.
- **Verificar antes de cambiar la estructura:** antes del `ALTER TABLE` se cuenta cuántas fechas nulas hay. Si hubiera alguna, la restricción `NOT NULL` no se podría aplicar.
- **Consulta generada por IA:** el pedido no aclaraba el motor y la IA devolvió tres versiones (MySQL, SQL Server y PostgreSQL). Se usó la de PostgreSQL, porque `AGE()` tiene en cuenta si la persona ya cumplió años en el año en curso.
- **El resultado del `DELETE` depende del día de ejecución**, porque compara con `CURRENT_DATE`. Ejecutado después del 2 de octubre de 2026, solo borra el turno del 20 de noviembre.
