# scripts/ghost_runner.py
import time
import logging
import config
from reconocimiento.models import IntentoReconocimiento
logging.basicConfig(filename=config.LOG_DIR+"/runner.log", level=logging.INFO)
while True:
    intento = IntentoReconocimiento.objects.create(url="bucle")
    logging.info(f"Intento {intento.id}")
    time.sleep(config.delay)
