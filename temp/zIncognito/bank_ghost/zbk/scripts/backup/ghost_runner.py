import time
import subprocess
import json
import os
import django
from django.conf import settings
from reconocimiento.models import IntentoReconocimiento
from django.core.files import File
from datetime import datetime

# Configura entorno Django
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "bank_ghost.settings")
os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
django.setup()

CONFIG_PATH = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_config.json')
SCRIPT_PATH = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')

def registrar_intento_desde_log(log_path, captura_path):
    if not os.path.exists(log_path):
        print(f"⚠️ Log no encontrado: {log_path}")
        return

    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(label):
        for linea in contenido.splitlines():
            if linea.startswith(label):
                return linea.split(":", 1)[1].strip()
        return ""

    timestamp = extraer_linea("Fecha")
    user_agent = extraer_linea("User-Agent")
    url = extraer_linea("URL")
    ids = extraer_linea("Identificadores buscados")
    reconocio = "SÍ" in extraer_linea("Reconocido")

    intento = IntentoReconocimiento(
        fecha=datetime.now(),
        url=url,
        identificadores=ids,
        user_agent=user_agent,
        reconocio=reconocio,
    )

    with open(captura_path, "rb") as cfile:
        intento.captura.save(os.path.basename(captura_path), File(cfile), save=False)

    with open(log_path, "rb") as lfile:
        intento.log.save(os.path.basename(log_path), File(lfile), save=False)

    intento.save()
    print(f"✅ Intento registrado en la base de datos para {url}")

def cargar_config():
    with open(CONFIG_PATH, encoding="utf-8") as f:
        return json.load(f)

contador = 1

while True:
    cfg = cargar_config()
    for url in cfg["urls"]:
        print(f"🚀 Ejecutando Ghost Recon sobre: {url}")

        cmd = [
            "python3",
            SCRIPT_PATH,
            url,
            ",".join(cfg["identificadores"]),
            str(cfg["repeticiones"]),
            str(cfg["delay"])
        ]
        subprocess.run(cmd)

        timestamp = time.strftime('%Y%m%d_%H%M%S')
        log_basename = f"log_{contador}_{timestamp}.txt"
        captura_basename = f"captura_{contador}_{timestamp}.png"

        log_path = os.path.join("logs", log_basename)
        captura_path = os.path.join("capturas", captura_basename)

        registrar_intento_desde_log(log_path, captura_path)
        contador += 1

    print(f"🕒 Esperando {cfg['delay']}s antes de nueva ronda...\n")
    time.sleep(cfg["delay"])
