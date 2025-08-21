from .base1 import *
from pathlib import Path
import os

# Cargamos primero el env.txt
from dotenv import load_dotenv
load_dotenv(Path(BASE_DIR) / '.env.production')

# Configuración de producción
DEBUG = False
DJANGO_ENV = 'production'

# Configuración de seguridad
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Configuración de caché optimizada
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
        'TIMEOUT': 300,
        'OPTIONS': {
            'MAX_ENTRIES': 1000,
            'CULL_FREQUENCY': 3,
        }
    }
}

# Configuración de sesiones
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_AGE = 3600

# Configuración de archivos estáticos
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

# Configuración de base de datos optimizada
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydatabase',
        'USER': 'markmur88',
        'PASSWORD': 'Ptf8454Jd55',
        'HOST': 'localhost',
        'PORT': '5432',
        'OPTIONS': {
            'CONN_MAX_AGE': 600,
        }
    }
}

# Configuración de logging optimizada
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': os.path.join(BASE_DIR, 'logs', 'django.log'),
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'root': {
        'handlers': ['console', 'file'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}

# Configuración de middleware optimizada
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Para servir archivos estáticos
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'middleware.oficial_session.DetectarOficialMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'api.core.middleware.CurrentUserMiddleware',
]

# Configuración de WhiteNoise para archivos estáticos
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',
]

# Configuración de templates optimizada
TEMPLATES[0]['OPTIONS']['debug'] = False

# Configuración de OAuth2
USE_OAUTH2_UI = True

# Configuración de timeouts
TIMEOUT = 30
TIMEOUT_REQUEST = 60

# Configuración de hosts permitidos
ALLOWED_HOSTS = [
    'api.coretransapi.com',
    'www.api.coretransapi.com',
    '80.78.30.242',
    'localhost',
    '127.0.0.1',
]

# Configuración de CORS
CORS_ALLOWED_ORIGINS = [
    "https://api.coretransapi.com",
    "https://www.api.coretransapi.com",
    "https://193.150.166.1",
    "https://193.150.166.1:443",
]

CORS_ALLOW_CREDENTIALS = True