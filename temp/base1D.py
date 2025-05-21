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
    "api.gpt4",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

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

# === API Deutsche Bank ===
ORIGIN = os.getenv("API_ORIGIN", "https://api.db.com")
CLIENT_ID = os.getenv("DB_CLIENT_ID", "")
CLIENT_SECRET = os.getenv("DB_CLIENT_SECRET", "")
TOKEN_URL = os.getenv("DB_TOKEN_URL", "")
AUTH_URL = os.getenv("DB_AUTH_URL", "")
API_URL = os.getenv("DB_API_URL", "")
SCOPE = os.getenv("DB_SCOPE", "sepa_credit_transfers")

# Claves privadas para client_assertion
PRIVATE_KEY_PATH = os.getenv("PRIVATE_KEY_PATH", "keys/private_key.pem")
PRIVATE_KEY_KID = os.getenv("PRIVATE_KEY_KID", "clave-demo")

# Timeout de requests (en segundos)
TIMEOUT_REQUEST = int(os.getenv("TIMEOUT_REQUEST", 20))

# Configuración OAuth2 integrada
OAUTH2 = {
    "CLIENT_ID": CLIENT_ID,
    "CLIENT_SECRET": CLIENT_SECRET,
    "SCOPE": SCOPE,
    "AUTHORIZE_URL": AUTH_URL,
    "TOKEN_URL": TOKEN_URL,
    "REDIRECT_URI": os.getenv("OAUTH2_REDIRECT_URI", "http://localhost:8000/oauth2/callback/"),
    "TIMEOUT_REQUEST": TIMEOUT_REQUEST,
}
