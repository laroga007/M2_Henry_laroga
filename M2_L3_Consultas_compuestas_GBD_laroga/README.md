# Lecture 3: consultas compuestas y gestión de bases de datos

Práctica del Módulo 2 (SQL) de Henry Data Science, en **PostgreSQL** con DBeaver. Se trabaja sobre `ventasdb`, una base de ventas con clientes, productos, órdenes, ítems y un registro de auditoría.

## Contenido

Todos los scripts están en la carpeta `ventasdb/`.

| Archivo | Tema |
|---|---|
| `M2_L3_ventasdb_laroga.sql` | Creación y carga de la base |
| `M2_L3_ventasdb_caso1_limpieza_laroga.sql` | Limpieza de textos, separación de nombre y apellido, resumen mensual y detección de picos de ventas |
| `M2_L3_ventasdb_caso2_productos_laroga.sql` | Ventas por producto, filtros con `HAVING` y ranking de clientes |
| `M2_L3_ventasdb_caso3_joins_laroga.sql` | `JOIN` entre las cuatro tablas y operaciones de conjuntos (`UNION`, `INTERSECT`, `EXCEPT`) |
| `M2_L3_ventasdb_caso4_mantenimiento_laroga.sql` | Integridad, índices, trigger de auditoría, transacciones y vistas |
| `M2_L3_Homework_ventasdb_laroga.sql` | Homework: indicadores RFM, outliers en emails, conjuntos, FK, trigger de validación, transacción con `ROLLBACK` y extra mile |

## Cómo ejecutarlo

Los scripts **dependen unos de otros** y se ejecutan en este orden:

1. `M2_L3_ventasdb_laroga.sql`: crea la base desde cero (se puede volver a correr).
2. Casos 1 a 4, en orden. El caso 1 agrega las columnas `first_name` y `last_name`; el caso 4 crea los índices, el trigger de auditoría y las vistas.
3. El homework, que usa todo lo anterior.

Conviene ejecutarlos **por bloques**: el caso 4 incluye dos `INSERT` que dan error a propósito para probar las claves foráneas, y ese error corta la ejecución.

El homework borra la orden 5, que es la orden de prueba que crea el caso 4. Si el caso 4 se corrió más de una vez, el número cambia: conviene revisarlo antes con `SELECT * FROM orders;`.

## Homework

| Parte | Qué se hace |
|---|---|
| Datos temporales y textuales | Última orden de cada cliente y días sin comprar; detección y conteo de emails mal registrados |
| Agregación | Frecuencia de compra, valor monetario por cliente y dispersión de las cantidades por producto |
| Consultas compuestas | Listado de compras uniendo las cuatro tablas; clientes por categoría con `INTERSECT`, `UNION` y `EXCEPT` |
| Gestión de la base | Índice en `orders`, FK de `audit_logs` a `customers`, trigger que registra cantidades inválidas y transacción con `ROLLBACK` |
| Extra mile | Carga de datos nuevos, vista de ventas por trimestre y categoría y función que segmenta clientes |

Las tres primeras partes arman los indicadores **RFM** de cada cliente: hace cuánto compró (*Recency*), con qué frecuencia (*Frequency*) y cuánto gastó (*Monetary*).

## Decisiones e inconsistencias de la consigna

- **Trimestre sin datos (caso 1):** la consulta original buscaba clientes de abril a junio, donde no hay ninguno. Se usó enero a marzo, que tiene datos.
- **Orden de prueba borrada:** la orden 5 se creó en el caso 4 solo para probar el trigger, sin ítems. Se eliminó porque distorsionaba los indicadores, pero su registro en `audit_logs` se conservó: la auditoría guarda lo que pasó.
- **`LEFT JOIN` y `COUNT(o.order_id)`:** para no perder a los clientes sin compras. `COUNT(*)` les asignaría 1 orden en lugar de 0.
- **Desvío `NULL` y no 0:** un producto con una sola venta no permite medir variación. 0 significaría "no varía", y no es lo mismo.
- **FK de `audit_logs` a `customers`:** la consigna pedía que `user_info` apuntara a los clientes, pero esa columna tiene valores como `admin` o `postgres`, que no son clientes. Se agregó una columna `customer_id` aparte, con su FK, y se completó cuando el usuario coincidía con el email del cliente.
- **Trigger de cantidades inválidas:** si rechazara la fila con un error, también se perdería el registro en `audit_logs`. Por eso registra el intento, avisa y descarta la fila sin dar error.
- **Vista en lugar de repetir `WITH`:** las operaciones de conjuntos del homework usan una vista con cada cliente y sus categorías, en lugar de repetir las mismas dos CTE en cada consulta.
- **Datos nuevos antes del extra mile:** con los datos originales (3 clientes, todo en abril de 2024) la vista por trimestre y la segmentación no tenían qué mostrar. Los datos nuevos fueron generados con IA e incluyen dos emails con errores a propósito, para probar la detección.
- **Segmento "Sin compras":** la consigna no contemplaba clientes con 0 órdenes. Se agregó ese segmento en lugar de dejarlos en `NULL` o clasificarlos como "Nuevo".
- **Ventas "acumuladas":** se interpretaron como el total de cada trimestre. Un acumulado progresivo requiere funciones de ventana, que se ven en la Lecture 4.
