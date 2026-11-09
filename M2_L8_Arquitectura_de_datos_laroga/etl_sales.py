# etl_sales.py
import csv, os, sys, datetime as dt

RAW_DIR = "data/raw"
WH_DIR  = "data/warehouse"
LOG     = "etl.log"

os.makedirs(WH_DIR, exist_ok=True)

def log(msg):
    ts = dt.datetime.now().isoformat(timespec="seconds")
    with open(LOG, "a") as f:
        f.write(f"[{ts}] {msg}\n")
    print(f"[{ts}] {msg}")

def run_etl(fecha=None):
    # Fecha a procesar (AAAA-MM-DD). Sin fecha, toma la de hoy, como en una carga nocturna real.
    # Los datos de la demo son del 2025-08-28 y 2025-08-29, así que se pasa la fecha a mano.
    today = fecha or dt.date.today().isoformat()
    raw_file = os.path.join(RAW_DIR, f"sales_{today}.csv")
    if not os.path.exists(raw_file):
        log(f"⚠ No existe {raw_file}, se omite.")
        return

    total = 0.0
    rows  = 0

    with open(raw_file, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows += 1
            total += float(r["amount"])

    out_file = os.path.join(WH_DIR, f"daily_sales_{today}.csv")
    with open(out_file, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["date", "orders", "total_amount_usd"])
        w.writerow([today, rows, f"{total:.2f}"])

    log(f"✅ ETL OK: {rows} órdenes, total ${total:.2f} → {out_file}")

if __name__ == "__main__":
    # Uso: python etl_sales.py 2025-08-29   (sin fecha = hoy)
    run_etl(sys.argv[1] if len(sys.argv) > 1 else None)
