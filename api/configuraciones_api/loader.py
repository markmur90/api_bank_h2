import os
from django.core.exceptions import ImproperlyConfigured

# def cargar_variables_entorno(entorno='production'):
#     try:
#         from api.configuraciones_api.models import ConfiguracionAPI
#         configuraciones = ConfiguracionAPI.objects.filter(entorno=entorno, activo=True)
#         for config in configuraciones:
#             if config.nombre not in os.environ:
#                 os.environ[config.nombre] = config.valor
#     except Exception as e:
#         if 'no such table' in str(e).lower():
#             pass  # Primera migración: ignorar
#         else:
#             raise ImproperlyConfigured(f"Error cargando configuración desde BD: {e}")

from functools import lru_cache
from api.configuraciones_api.helpers import get_conf

@lru_cache
def get_settings():
    timeout = int(600)
    port = int(get_conf("MOCK_PORT"))
    return {
        "dns_banco":            get_conf("DNS_BANCO"),
        "dominio_banco":        get_conf("DOMINIO_BANCO"),
        "red_segura_prefix":    get_conf("RED_SEGURA_PREFIX"),
        "allow_fake_bank":      get_conf("ALLOW_FAKE_BANK"),
        "token_url":            get_conf("TOKEN_URL"),
        "token_path":           get_conf("TOKEN_PATH"),
        "authorize_url":        get_conf("AUTHORIZE_URL"),
        "authorize_path":       get_conf("AUTHORIZE_PATH"),
        "otp_url":              get_conf("OTP_URL"),
        "otp_path":             get_conf("OTP_PATH"),
        "auth_url":             get_conf("AUTH_URL"),
        "auth_path":            get_conf("AUTH_PATH"),
        "api_url":              get_conf("API_URL"),
        "api_path":             get_conf("API_PATH"),
        "debug":                get_conf("DEBUG"),
        "allowed_host":         get_conf("ALLOWED_HOST"),
        "secret_key":           get_conf("SECRET_KEY"),
        "environment":          get_conf("ENVIRONMENT"),
        "django_env":           get_conf("DJANGO_ENV"),
        "redirect_uri":         get_conf("REDIRECT_URI"),
        "origin":               get_conf("ORIGIN"),
        "client_id":            get_conf("CLIENT_ID"),
        "client_secret":        get_conf("CLIENT_SECRET"),
        "scope":                get_conf("SCOPE"),
        "private_key_path":     get_conf("PRIVATE_KEY_PATH"),
        "private_key_kid":      get_conf("PRIVATE_KEY_KID"),
        "jwt_signing_key":      get_conf("JWT_SIGNING_KEY"),
        "jwt_verifying_key":    get_conf("JWT_VERIFYING_KEY"),
        "timeout":              timeout,
        "mock_port":            port,
    }
    
def cargar_variables_entorno(entorno=None, request=None):
    from api.configuraciones_api.models import ConfiguracionAPI

    if request and 'entorno_actual' in request.session:
        entorno = request.session['entorno_actual']
    elif not entorno:
        entorno = os.getenv('DJANGO_ENV', 'production')

    configuraciones = ConfiguracionAPI.objects.filter(entorno=entorno, activo=True)
    for config in configuraciones:
        if config.nombre not in os.environ:
            os.environ[config.nombre] = config.valor
