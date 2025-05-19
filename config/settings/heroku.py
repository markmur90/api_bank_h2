from .baseF import *

import os
from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
DJANGO_ENV = os.getenv('DJANGO_ENV', 'heroku')
env_file = BASE_DIR / f'.env.{DJANGO_ENV}'
env.read_env(env_file)

SECRET_KEY = env('SECRET_KEY')
DEBUG = env.bool('DEBUG', default=False)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=['.herokuapp.com'])

DATABASES = {
    'default': env.db('DATABASE_URL')
}

# Ajustes para Heroku
import django_heroku
django_heroku.settings(locals(), logging=False)

# Desactiva colecta automática de estáticos en producción si no usas WhiteNoise
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

