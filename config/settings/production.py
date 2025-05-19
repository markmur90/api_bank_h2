from .baseF import *

import dj_database_url
import os
from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()
DJANGO_ENV = os.getenv('DJANGO_ENV', 'production')
env_file = BASE_DIR / f'.env.{DJANGO_ENV}'
env.read_env(env_file)


# 3. Variables críticas
SECRET_KEY = env('SECRET_KEY')
DEBUG = False
ALLOWED_HOSTS = ['.herokuapp.com']

# Configuración estática para Heroku
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Archivos media (si los usas)
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

# Whitenoise para servir archivos estáticos eficientemente
MIDDLEWARE.insert(1, 'whitenoise.middleware.WhiteNoiseMiddleware')
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Seguridad recomendada en producción
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = 'DENY'

# Base de datos desde DATABASE_URL de Heroku
DATABASES['default'] = dj_database_url.config(conn_max_age=600, ssl_require=True)


# Ajustes para Heroku
import django_heroku
django_heroku.settings(locals(), logging=False)

