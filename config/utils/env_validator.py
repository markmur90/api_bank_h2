import os
import logging
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent
LOG_DIR = BASE_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)
LOG_FILE = LOG_DIR / "env_validator.log"

logging.basicConfig(
    filename=LOG_FILE,
    level=logging.ERROR,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)

def validar_variables_entorno(env):
    claves_requeridas = [
        "SECRET_KEY",
        "DATABASE_URL",
        "PRIVATE_KEY_PATH",
        "JWT_SIGNING_KEY"
    ]

    errores = []
    for clave in claves_requeridas:
        if not env(clave, default=None):
            errores.append(f"❌ Falta la variable: {clave}")

    if errores:
        for e in errores:
            print(e)
            logging.error(e)
        raise ValueError("🚫 Error crítico: variables de entorno faltantes. Ver logs/env_validator.log")
