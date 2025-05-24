from .base1 import *

from pathlib import Path
import environ

BASE_DIR = Path(__file__).resolve().parent.parent.parent

# 1. Creamos el lector de .env
env = environ.Env()

# 2. Detectamos el entorno (por defecto 'local') y cargamos el .env correspondiente
DJANGO_ENV = os.getenv('DJANGO_ENV', 'production')
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


CLIENT_ID = env('CLIENT_ID')
CLIENT_SECRET = env('CLIENT_SECRET')

ORIGIN = env('ORIGIN')

TOKEN_URL = env('TOKEN_URL')
OTP_URL = env('OTP_URL')
AUTH_URL = env('AUTH_URL')
API_URL = env('API_URL')
AUTHORIZE_URL = env('AUTHORIZE_URL')
SCOPE = env('SCOPE')
TIMEOUT_REQUEST = env('TIMEOUT_REQUEST')

ACCESS_TOKEN = env('ACCESS_TOKEN')

OAUTH2.update({
    'CLIENT_ID': CLIENT_ID,
    'CLIENT_SECRET': CLIENT_SECRET,
    'ACCESS_TOKEN': ACCESS_TOKEN,
    'ORIGIN': ORIGIN,
    'OTP_URL': OTP_URL,
    'AUTH_URL': AUTH_URL,
    'API_URL': API_URL,
    'TOKEN_URL': TOKEN_URL,
    'AUTHORIZE_URL': AUTHORIZE_URL,
    'SCOPE': SCOPE,
    'TIMEOUT': TIMEOUT_REQUEST,
})

