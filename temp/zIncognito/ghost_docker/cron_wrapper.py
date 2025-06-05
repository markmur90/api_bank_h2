#!/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/venv/bin/python3

import subprocess
import datetime
import requests
import os
import time

TELEGRAM_TOKEN = "6983248274:AAGyNmK_IeXh-yN1PQsGDqmEaghhNqig6Js"
CHAT_ID = "769077177"

base_dir = "/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
script_path = os.path.join(base_dir, "ghost_recon_ultimate.py")
log_path = f"{base_dir}/logs/cron_ghost.log"
output_path = f"{base_dir}/logs/cron_output_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
log_success = True

# Asegurar existencia de carpeta logs
try:
    os.makedirs(os.path.dirname(log_path), exist_ok=True)
except Exception as e:
    log_success = False

start_time = time.time()

# Ejecutar comando principal
try:
    result = subprocess.run([
        "python3", script_path,
        "https://developer.db.com", "Markmur88,usuario,bienvenido", "1", "0"
    ], capture_output=True, text=True, check=True)

    duration = round((time.time() - start_time) * 1000)
    message = f"✅ Reconocimiento ejecutado OK: {timestamp} (⏱ {duration} ms)"
    status = "OK"

except subprocess.CalledProcessError as e:
    duration = round((time.time() - start_time) * 1000)
    message = f"❌ Error en reconocimiento: {timestamp} (⏱ {duration} ms)\n{e.stderr}"
    status = "ERROR"
    result = e

# Guardar salida completa en archivo separado
try:
    with open(output_path, "w") as fout:
        fout.write(result.stdout or "")
        fout.write("\n")
        fout.write(result.stderr or "")
except Exception as e:
    message += f"\n⚠️ No se pudo guardar salida completa: {e}"

# Intentar escribir resumen en el log general
try:
    with open(log_path, "a") as f:
        f.write(f"[{timestamp}] {status} ({duration} ms)\n")
except Exception as e:
    log_success = False
    message += f"\n⚠️ No se pudo escribir en log: {e}"

# Enviar a Telegram
try:
    requests.post(
        f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
        data={"chat_id": CHAT_ID, "text": message}
    )
except Exception as e:
    print(f"❌ Falló el envío a Telegram: {e}")

print("✅ Finalizado. Resultado:", status)
print(f"📂 Salida completa guardada en: {output_path}")