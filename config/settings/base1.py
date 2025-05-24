import os
from pathlib import Path
import environ
import dj_database_url

env = environ.Env()

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = env("SECRET_KEY", default=None)
if not SECRET_KEY:
    raise ValueError("🚨 SECRET_KEY no definida en entorno")

DEBUG = os.getenv("DJANGO_DEBUG", "True") == "True"
ALLOWED_HOSTS = os.getenv("ALLOWED_HOSTS", "").split(",")



# 4. Apps y middleware (sin cambios)
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    'drf_yasg',
    'rest_framework',
    'oauth2_provider',
    'rest_framework_simplejwt',
    'corsheaders',
    'debug_toolbar',
    'rest_framework.authtoken',
    'markdownify',

    'api.transfers',
    'api.core',
    'api.authentication',
    
    # 'api.transactions',

    # 'api.accounts',
    # 'api.collection',
    # 'api.sandbox',
    # 'api.sct',
    # 'api.sepa_payment',
    # 'api.gpt',

    'api.gpt3',
    'api.gpt4',
]

MIDDLEWARE = [
    'debug_toolbar.middleware.DebugToolbarMiddleware',
    "api.middleware.ExceptionLoggingMiddleware",
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'api.core.middleware.CurrentUserMiddleware',
]


ROOT_URLCONF = 'config.urls'
WSGI_APPLICATION = 'config.wsgi.application'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# 4. DEBUG_TOOLBAR_SETTINGS (opcional, pero recomendado)
INTERNAL_IPS = [
    '127.0.0.1',
    '192.168.0.143'
    # añade aquí la IP de tu máquina si usas Docker o VM
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "mydatabase"),
        "USER": os.getenv("DB_USER", "markmur88"),
        "PASSWORD": os.getenv("DB_PASS", "Ptf8454Jd55"),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
    }
}


# 6. Resto de configuración (sin cambios)
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Europe/Berlin'
USE_I18N = True
USE_L10N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
STATIC_TMP =os.path.join(BASE_DIR, 'static')
os.makedirs(STATIC_TMP, exist_ok=True)
os.makedirs(STATIC_ROOT, exist_ok=True)

STATICFILES_DIRS = [STATIC_TMP]
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# CORS
CORS_ORIGIN_ALLOW_ALL = False  # ⚠️ Desactívalo aquí
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGINS = [
    "https://api.db.com",
    "https://simulator-api.db.com",
    "https://apibank2-d42d7ed0d036.herokuapp.com",
    "https://api.coretransapi.com",
]

# REST Framework y OAuth/JWT (sin cambios)
from datetime import timedelta
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'oauth2_provider.contrib.rest_framework.OAuth2Authentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': ('rest_framework.permissions.AllowAny',),
}

OAUTH2_PROVIDER = {'ACCESS_TOKEN_EXPIRE_SECONDS': 3600, 'OIDC_ENABLED': True}

# === API Deutsche Bank ===
ORIGIN = os.getenv("API_ORIGIN", "https://api.db.com")
CLIENT_ID = os.getenv("DB_CLIENT_ID", "")
CLIENT_SECRET = os.getenv("DB_CLIENT_SECRET", "")
TOKEN_URL = os.getenv("DB_TOKEN_URL", "")
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN", "")
AUTH_URL = os.getenv("DB_AUTH_URL", "")
AUTHORIZE_URL = os.getenv("DB_AUTHORIZE_URL", "")
API_URL = os.getenv("DB_API_URL", "")
SCOPE = os.getenv("DB_SCOPE", "sepa_credit_transfers")
TIMEOUT_REQUEST = int(os.getenv("TIMEOUT_REQUEST", 3600))

# Configuración OAuth2 integrada
OAUTH2 = {
    "CLIENT_ID": CLIENT_ID,
    "CLIENT_SECRET": CLIENT_SECRET,
    "SCOPE": SCOPE,
    "AUTH_URL": AUTH_URL,
    "AUTHORIZE_URL": AUTHORIZE_URL,
    "TOKEN_URL": TOKEN_URL,
    "ACCESS_TOKEN": ACCESS_TOKEN,
    "REDIRECT_URI": os.getenv("OAUTH2_REDIRECT_URI", "http://localhost:8011/oauth2/callback/"),
    "TIMEOUT_REQUEST": TIMEOUT_REQUEST,
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
    "ALGORITHM": "HS256",
    "SIGNING_KEY": env('JWT_SIGNING_KEY', default=''),
    "VERIFYING_KEY": env('JWT_VERIFYING_KEY', default=''),
    "AUTH_HEADER_TYPES": ("Bearer",),
}

# Logging (sin cambios)
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {"format": "{levelname} {asctime} {module} {message}", "style": "{"},
        "simple": {"format": "{levelname} {message}", "style": "{"},
    },
    "handlers": {
        "file": {
            "level": "WARNING",
            "class": "logging.FileHandler",
            "filename": BASE_DIR / "logs" / "errors.log",
            "formatter": "verbose",
        },
        "console": {"level": "INFO", "class": "logging.StreamHandler", "formatter": "simple"},
    },
    "loggers": {
        "django": {"handlers": ["file", "console"], "level": "WARNING", "propagate": True},
        "bank_services": {"handlers": ["file", "console"], "level": "INFO", "propagate": False},
    },
}

LOGIN_URL = '/login/'
SESSION_COOKIE_AGE = 1800
SESSION_EXPIRE_AT_BROWSER_CLOSE = True

DEBUG_TOOLBAR_CONFIG = {
    'INTERCEPT_REDIRECTS': False,
}

PRIVATE_KEY_KID = '207230d7-f5f4-4bf1-929d-d17e5594ef98'
PRIVATE_KEY_PATH = os.path.join(BASE_DIR, 'schemas', 'keys', 'ecdsa_private_key.pem')


from config.utils.validar_entorno import validar_variables
validar_variables()