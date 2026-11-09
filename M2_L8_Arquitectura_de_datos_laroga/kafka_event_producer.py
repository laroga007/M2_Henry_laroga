# kafka_event_producer.py
import json, time, random, datetime as dt
from kafka import KafkaProducer

PRODUCTS = ["P101","P102","P103","P104","P105"]
CUSTOMERS = ["U001","U002","U003","U004","U005"]

def make_event(i):
    evt = {
        "event_id": f"E{str(i).zfill(6)}",
        "timestamp": dt.datetime.now(dt.timezone.utc).replace(tzinfo=None).isoformat(timespec="seconds"),  # utcnow() está deprecado
        "customer_id": random.choice(CUSTOMERS),
        "event_type": random.choice(["view","add_to_cart","purchase","search"]),
        "product_id": random.choice(PRODUCTS),
    }
    if evt["event_type"] == "purchase":
        evt["amount"] = round(random.uniform(10, 300), 2)
        evt["currency"] = "USD"
    return evt

def main():
    producer = KafkaProducer(bootstrap_servers="localhost:9092",
                             value_serializer=lambda v: json.dumps(v).encode())
    topic = "datashop_events"
    i = 1
    print("⏩ Enviando eventos a Kafka (Ctrl+C para salir)...")
    try:
        while True:
            evt = make_event(i)
            producer.send(topic, evt)
            producer.flush()
            print("→", evt)
            i += 1
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nDetenido por usuario.")

if __name__ == "__main__":
    main()
