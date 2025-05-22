# config/settings/__init__.py

import os
import environ
from pathlib import Path
import sys

# Define entorno: 'local', 'heroku', 'production', etc.
DJANGO_ENV = os.getenv('DJANGO_ENV', 'local').lower()
BASE_DIR = Path(__file__).resolve().parent.parent.parent
env = environ.Env()
env_path = BASE_DIR / f'.env.{DJANGO_ENV}'

# Función para mostrar solo si salida es TTY (no redirección)
def safe_echo(msg):
    if sys.stdout.isatty():  # Solo si es consola interactiva
        print(msg)

safe_echo(f"[settings] DJANGO_ENV = {DJANGO_ENV}")

if env_path.exists():
    env.read_env(env_path)
    safe_echo(f"[settings] Variables cargadas desde: {env_path}")
else:
    fallback_path = BASE_DIR / '.env'
    if fallback_path.exists():
        env.read_env(fallback_path)
        safe_echo(f"[settings] Archivo .env.{DJANGO_ENV} no encontrado. Usando fallback: {fallback_path}")
    else:
        safe_echo(f"⚠️  No se encontró .env.{DJANGO_ENV} ni .env. Continuando sin cargar variables.")

# Importa los settings según el entorno
if DJANGO_ENV == 'heroku':
    from .heroku import *
elif DJANGO_ENV == 'production':
    from .production import *
else:
    from .local import *
