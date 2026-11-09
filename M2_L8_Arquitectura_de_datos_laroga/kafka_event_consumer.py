# kafka_event_consumer.py
# Lee los eventos de DataShop guardados en Kafka y los procesa:
#   - cuenta los eventos por tipo (lo que vería un dashboard en tiempo real)
#   - suma las compras
#   - marca como posible fraude a un cliente con 2 o más compras en menos de 10 segundos
#
# Lee el topic desde el principio, así que también procesa eventos enviados antes:
# Kafka los conserva, que es lo que permite reprocesar el histórico (arquitectura Kappa).
import json, datetime as dt
from collections import Counter, defaultdict
from kafka import KafkaConsumer

TOPIC = "datashop_events"
VENTANA_FRAUDE_SEG = 10   # segundos entre compras del mismo cliente
COMPRAS_SOSPECHOSAS = 2   # compras dentro de esa ventana para alertar

def main():
    consumer = KafkaConsumer(
        TOPIC,
        bootstrap_servers="localhost:9092",
        auto_offset_reset="earliest",   # desde el primer evento guardado
        consumer_timeout_ms=5000,       # termina si no llegan eventos en 5 segundos
    )

    por_tipo = Counter()
    total_compras = 0.0
    compras_por_cliente = defaultdict(list)
    alertas = []

    print(f"⏩ Leyendo eventos de '{TOPIC}'...")
    for msg in consumer:
        evt = json.loads(msg.value.decode("utf-8"))
        por_tipo[evt["event_type"]] += 1

        if evt["event_type"] == "purchase":
            total_compras += evt["amount"]
            momento = dt.datetime.fromisoformat(evt["timestamp"])
            recientes = [t for t in compras_por_cliente[evt["customer_id"]]
                         if (momento - t).total_seconds() <= VENTANA_FRAUDE_SEG]
            recientes.append(momento)
            compras_por_cliente[evt["customer_id"]] = recientes
            if len(recientes) >= COMPRAS_SOSPECHOSAS:
                alertas.append((evt["event_id"], evt["customer_id"], len(recientes)))
                print(f"🚨 Posible fraude: {evt['customer_id']} con {len(recientes)} compras "
                      f"en {VENTANA_FRAUDE_SEG}s (evento {evt['event_id']})")

    consumer.close()

    print("\nResumen")
    print(f"  Eventos leídos: {sum(por_tipo.values())}")
    for tipo, cantidad in por_tipo.most_common():
        print(f"  {tipo}: {cantidad}")
    print(f"  Total en compras: ${total_compras:.2f}")
    print(f"  Alertas de fraude: {len(alertas)}")

if __name__ == "__main__":
    main()
