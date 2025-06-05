# servers/gunicorn/gunicorn.conf.py
import sys
import os
import time

# ———————— Aseguramos que el proyecto esté en el PYTHONPATH ————————
# __file__ = .../servers/gunicorn/gunicorn.conf.py
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

import config  # ahora siempre encuentra config.py en la raíz del proyecto

# ———————— Espera inicial ————————
WAIT_TIMEOUT = 5.0    # segundos máximos a esperar
WAIT_INTERVAL = 0.5   # intervalo de comprobación
elapsed = 0.0
while not os.path.isdir(config.GUNICORN_DIR) and elapsed < WAIT_TIMEOUT:
    time.sleep(WAIT_INTERVAL)
    elapsed += WAIT_INTERVAL

if not os.path.isdir(config.GUNICORN_DIR):
    print(f"Warning: no existe el directorio de Gunicorn: {config.GUNICORN_DIR}")
else:
    print(f"Directory {config.GUNICORN_DIR} disponible tras {elapsed:.1f}s de espera")

# ———————— Configuración de Gunicorn ————————
bind        = f"unix:{config.SOCK_FILE}"
workers     = 3
timeout     = 120  # segundos antes de reiniciar workers
accesslog   = config.GUNICORN_LOG
errorlog    = config.ERROR_LOG
