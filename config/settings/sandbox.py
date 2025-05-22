from .baseF import *

import os
from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
DJANGO_ENV = os.getenv('DJANGO_ENV', 'sandbox')
env_file = BASE_DIR / f'.env.{DJANGO_ENV}'
env.read_env(env_file)

SECRET_KEY = env('SECRET_KEY')
DEBUG = env.bool('DEBUG', default=True)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['localhost', '127.0.0.1'])

DATABASES = {
    'default': env.db('DATABASE_URL')
}

# Seguridad relajada para pruebas
CORS_ORIGIN_ALLOW_ALL = True
CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])
