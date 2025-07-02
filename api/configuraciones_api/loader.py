# api/configuraciones_api/loader.py
import os
from django.core.exceptions import ImproperlyConfigured
from functools import lru_cache
from api.configuraciones_api.helpers import get_conf

@lru_cache
def get_settings() -> dict:
    """
    Carga las configuraciones desde tabla ConfiguracionAPI o env vars.
    """
    entorno = os.getenv('DJANGO_ENV', 'production')

    # Timeout global (puede venir de env o DB)
    timeout_env = os.getenv('TIMEOUT')
    try:
        timeout = int(timeout_env) if timeout_env is not None else int(get_conf('TIMEOUT', entorno))
    except Exception:
        timeout = 600

    # Mock port
    try:
        mock_port = int(get_conf('MOCK_PORT', entorno))
    except ValueError as e:
        raise ImproperlyConfigured(f"MOCK_PORT inválido para entorno {entorno}: {e}")

    # Host y puerto bancario (prioridad a env vars)
    bank_host = os.getenv('BANK_HOST') or get_conf('DNS_BANCO', entorno)
    bank_port = int(os.getenv('BANK_PORT') or get_conf('DOMINIO_BANCO', entorno) or 0)

    # Modo mock (flag)
    allow_mock_env = os.getenv('BANK_ALLOW_MOCK')
    if allow_mock_env is not None:
        bank_allow_mock = allow_mock_env.lower() in ('1','true','yes')
    else:
        bank_allow_mock = get_conf('ALLOW_FAKE_BANK', entorno).lower() in ('1','true','yes')

    return {
        'bank_host': bank_host,
        'bank_port': bank_port,
        'bank_verify_ssl': os.getenv('BANK_VERIFY_SSL', 'True').lower() in ('1','true','yes'),
        'red_segura_prefix': os.getenv('RED_SEGURA_PREFIX') or get_conf('RED_SEGURA_PREFIX', entorno),
        'bank_allow_mock': bank_allow_mock,
        'mock_port': mock_port,
        'timeout': timeout,
        'access_token': get_conf('ACCESS_TOKEN', entorno),
        'token_url': get_conf('TOKEN_URL', entorno),
        'token_path': get_conf('TOKEN_PATH', entorno),
        'authorize_url': get_conf('AUTHORIZE_URL', entorno),
        'authorize_path': get_conf('AUTHORIZE_PATH', entorno),
        'otp_url': get_conf('OTP_URL', entorno),
        'otp_path': get_conf('OTP_PATH', entorno),
        'totp_secret': os.getenv('TOTP_SECRET') or get_conf('TOTP_SECRET', entorno),
        'api_url': get_conf('API_URL', entorno),
        'api_path': get_conf('API_PATH', entorno),
        'jwt_signing_key': get_conf('JWT_SIGNING_KEY', entorno),
        'jwt_verifying_key': get_conf('JWT_VERIFYING_KEY', entorno),
        'client_id': get_conf('CLIENT_ID', entorno),
        'client_secret': get_conf('CLIENT_SECRET', entorno),
        'scope': os.getenv('SCOPE') or get_conf('SCOPE', entorno),
        'origin': get_conf('ORIGIN', entorno),
        'redirect_uri': get_conf('REDIRECT_URI', entorno),
        'environment': entorno,
        'debug': get_conf('DEBUG', entorno),
        'allowed_host': get_conf('ALLOWED_HOST', entorno),
    }


def cargar_variables_entorno(entorno: str = None, request=None) -> None:
    """
    Vuelca todas las configuraciones activas de la tabla ConfiguracionAPI
    al entorno OS (os.environ), para que Django las lea como variables de entorno.
    Se puede forzar un 'entorno' o usar el de la sesión HTTP.
    """
    # Import lazy del modelo (asegura que apps ya estén cargadas)
    from api.configuraciones_api.models import ConfiguracionAPI

    # Si la petición tiene un entorno en sesión, lo usamos; si no, el de OS
    if request and request.session.get('entorno_actual'):
        entorno = request.session['entorno_actual']
    else:
        entorno = entorno or os.getenv('DJANGO_ENV', 'production')

    # Obtenemos sólo las configuraciones activas para ese entorno
    configuraciones = ConfiguracionAPI.objects.filter(entorno=entorno, activo=True)

    for config in configuraciones:
        # No sobreescribimos si ya está en os.environ
        os.environ.setdefault(config.nombre, config.valor)
