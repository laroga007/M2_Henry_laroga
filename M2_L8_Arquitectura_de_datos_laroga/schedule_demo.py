# schedule_demo.py
import schedule, time
from etl_sales import run_etl, log

# Fecha fija de la demo: con la fecha de hoy no hay archivo de ventas
FECHA_DEMO = "2025-08-29"
schedule.every(10).seconds.do(run_etl, FECHA_DEMO)

log("⏰ Scheduler iniciado (demo cada 10s). Ctrl+C para detener.")
try:
    while True:
        schedule.run_pending()
        time.sleep(1)
except KeyboardInterrupt:
    log("🛑 Scheduler detenido por el usuario.")
