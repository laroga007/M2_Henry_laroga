# DataShop Demo

Este paquete incluye datasets y scripts de ejemplo para la clase "Fundamentos de Arquitectura de Datos".

## Contenido

- `data/dim/customers.csv`: clientes ficticios
- `data/dim/products.csv`: productos ficticios
- `data/raw/sales_*.csv`: ventas diarias simuladas
- `data/raw/clickstream_events.ndjson`: eventos clickstream
- `etl_sales.py`: ETL batch para consolidar ventas
- `schedule_demo.py`: automatización con schedule (demo cada 10s)
- `kafka_event_producer.py`: generador de eventos a Kafka

## Uso rápido

1. Ejecutar `etl_sales.py` para consolidar ventas del día.
2. Ejecutar `schedule_demo.py` para ver automatización.
3. (Opcional) Levantar Kafka con Docker y usar `kafka_event_producer.py`.
