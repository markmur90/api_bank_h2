from .base1 import *

from pathlib import Path
import environ
from django.core.exceptions import ImproperlyConfigured
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent.parent

env = environ.Env()

DJANGO_ENV = os.getenv('DJANGO_ENV', 'production')
env_file = BASE_DIR / ('.env.production' if DJANGO_ENV == 'production' else '.env.development')
if not env_file.exists():
    raise ImproperlyConfigured(f'No se encuentra el archivo de entorno: {env_file}')
env.read_env(env_file)

ALLOWED_HOSTS = ['apibank2-54644cdf263f.herokuapp.com', 'apih.coretransapi.com']

SECRET_KEY = env('SECRET_KEY')
DEBUG = False

SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'

CLIENT_ID = env('CLIENT_ID')
CLIENT_SECRET = env('CLIENT_SECRET')
ACCESS_TOKEN = env('ACCESS_TOKEN')
ORIGIN = env('ORIGIN')
OTP_URL = env('OTP_URL')
AUTH_URL = env('AUTH_URL')
TOKEN_URL = env('TOKEN_URL')
API_URL = env('API_URL')
AUTHORIZE_URL = env('AUTHORIZE_URL')
SCOPE = env('SCOPE')
REDIRECT_URI = env('REDIRECT_URI')

OAUTH2 = {
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
    'REDIRECT_URI': REDIRECT_URI,
    'TIMEOUT_REQUEST': 3600,
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
    "ALGORITHM": "HS256",
    "SIGNING_KEY": env('JWT_SIGNING_KEY', default=''),
    "VERIFYING_KEY": env('JWT_VERIFYING_KEY', default=''),
    "AUTH_HEADER_TYPES": ("Bearer",),
}
