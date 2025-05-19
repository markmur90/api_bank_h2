import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.getenv("DJANGO_SECRET_KEY", "clave_insegura_dev")
DEBUG = os.getenv("DJANGO_DEBUG", "True") == "True"
ALLOWED_HOSTS = os.getenv("DJANGO_ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

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

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

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
        "NAME": os.getenv("POSTGRES_DB", "sepa"),
        "USER": os.getenv("POSTGRES_USER", "sepauser"),
        "PASSWORD": os.getenv("POSTGRES_PASSWORD", "password"),
        "HOST": os.getenv("POSTGRES_HOST", "localhost"),
        "PORT": os.getenv("POSTGRES_PORT", "5432"),
    }
}

# 6. Resto de configuración (sin cambios)
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = "es-co"
TIME_ZONE = "Europe/Berlin"
USE_I18N = True
USE_L10N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "mediafiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# CORS
CORS_ORIGIN_ALLOW_ALL = True
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOWED_ORIGINS = [
    "https://api.db.com",
    "https://simulator-api.db.com",
    "https://apibank2-d42d7ed0d036.herokuapp.com",
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


# === API Deutsche Bank ===
ORIGIN = os.getenv("API_ORIGIN", "https://api.db.com")
CLIENT_ID = os.getenv("DB_CLIENT_ID", "")
CLIENT_SECRET = os.getenv("DB_CLIENT_SECRET", "")
TOKEN_URL = os.getenv("DB_TOKEN_URL", "")
ACCESS_TOKEN = os.getenv("ACCESS_TOKEN", "")
AUTH_URL = os.getenv("DB_AUTH_URL", "")
API_URL = os.getenv("DB_API_URL", "")
SCOPE = os.getenv("DB_SCOPE", "sepa_credit_transfers")

# Claves privadas para client_assertion
# PRIVATE_KEY_PATH = os.getenv("PRIVATE_KEY_PATH", "keys/private_key.pem")
# PRIVATE_KEY_KID = os.getenv("PRIVATE_KEY_KID", "clave-demo")
# PRIVATE_KEY_PATH = "schemas/keys/ecdsa_private_key.pem"
# PRIVATE_KEY_KID = "clave-demo"

# Timeout de requests (en segundos)
TIMEOUT_REQUEST = int(os.getenv("TIMEOUT_REQUEST", 20))

# Configuración OAuth2 integrada
OAUTH2 = {
    "CLIENT_ID": CLIENT_ID,
    "CLIENT_SECRET": CLIENT_SECRET,
    "SCOPE": SCOPE,
    "AUTHORIZE_URL": AUTH_URL,
    "TOKEN_URL": TOKEN_URL,
    "ACCESS_TOKEN": ACCESS_TOKEN,
    "REDIRECT_URI": os.getenv("OAUTH2_REDIRECT_URI", "http://localhost:8000/oauth2/callback/"),
    "TIMEOUT_REQUEST": TIMEOUT_REQUEST,
}


SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=1),
    "ALGORITHM": "HS256",
    "SIGNING_KEY": os.getenv('JWT_SIGNING_KEY', default=''),
    "VERIFYING_KEY": os.getenv('JWT_VERIFYING_KEY', default=''),
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

