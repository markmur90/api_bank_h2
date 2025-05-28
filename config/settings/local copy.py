from .base1 import *

from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# 1. Creamos el lector de .env
env = environ.Env()

# 2. Detectamos el entorno (por defecto 'local') y cargamos el .env correspondiente
DJANGO_ENV = os.getenv('DJANGO_ENV', 'local')
env_file = BASE_DIR / ('.env.production' if DJANGO_ENV == 'production' else '.env.development')
if not env_file.exists():
    raise ImproperlyConfigured(f'No se encuentra el archivo de entorno: {env_file}')
env.read_env(env_file)

# 3. Variables críticas
SECRET_KEY = env('SECRET_KEY')
DEBUG      = env.bool('DEBUG', default=True)
ALLOWED_HOSTS = env.list('ALLOWED_HOSTS', default=[])


DATABASES = {
    'default': env.db('DATABASE_URL')
}


SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False

USE_OAUTH2_UI = False

REDIRECT_URI = env('REDIRECT_URI', default="http://0.0.0.0:8000/oauth2/callback/")
ORIGIN = env('ORIGIN', default="http://0.0.0.0:8000")

OAUTH2.update({
    "REDIRECT_URI": REDIRECT_URI,
    "ORIGIN": ORIGIN,
})

PRIVATE_KEY_PATH = os.path.join(BASE_DIR, 'schemas/keys', 'private_key.pem')
PRIVATE_KEY_KID = '7ed9e904-a421-4d49-8e9d-4a453b2d63c8'
