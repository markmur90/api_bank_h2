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

    # Timeout global (prioridad a env o DB)
    timeout_env = os.getenv('BANK_TIMEOUT')
    try:
        timeout = int(timeout_env) if timeout_env is not None else int(get_conf('TIMEOUT', entorno))
    except Exception:
        timeout = 600

    # Mock port
    try:
        mock_port = int(get_conf('MOCK_PORT', entorno))
    except ValueError as e:
        raise ImproperlyConfigured(f"MOCK_PORT inválido para entorno {entorno}: {e}")

    # Host y puerto bancario
    bank_host = os.getenv('BANK_HOST') or get_conf('DNS_BANCO', entorno)
    bank_port = int(os.getenv('BANK_PORT') or get_conf('DOMINIO_BANCO', entorno) or 0)

    # Modo mock
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
        'otp_url': get_conf('OTP_URL', entorno),
        'totp_secret': os.getenv('TOTP_SECRET') or get_conf('TOTP_SECRET', entorno),
        'api_url': get_conf('API_URL', entorno),
        'jwt_signing_key': get_conf('JWT_SIGNING_KEY', entorno),
        'scope': os.getenv('SCOPE') or get_conf('SCOPE', entorno),
        'environment': entorno,
        'debug': get_conf('DEBUG', entorno),
        
        # Agregar variables faltantes
        'base_url': get_conf('BASE_URL', entorno),
        'auth_url': get_conf('AUTH_URL', entorno),
        'authorize_url': get_conf('AUTHORIZE_URL', entorno),
        'login_url': get_conf('LOGIN_URL', entorno),
        'transfer_url': get_conf('TRANSFER_URL', entorno),
        'status_url': get_conf('STATUS_URL', entorno),
        'verify_url': get_conf('VERIFY_URL', entorno),
        'token_endpoint': get_conf('TOKEN_ENDPOINT', entorno),
        'challenge_url': get_conf('CHALLENGE_URL', entorno),
        'token_path': get_conf('TOKEN_PATH', entorno),
        'auth_path': get_conf('AUTH_PATH', entorno),
        'send_path': get_conf('SEND_PATH', entorno),
        'status_path': get_conf('STATUS_PATH', entorno),
        'verify_path': get_conf('VERIFY_PATH', entorno),
        'api_transfer_path': get_conf('API_TRANSFER_PATH', entorno),
        'simulador_api_url': get_conf('SIMULADOR_API_URL', entorno),
        'simulador_login_url': get_conf('SIMULADOR_LOGIN_URL', entorno),
        'simulador_verify_url': get_conf('SIMULADOR_VERIFY_URL', entorno),
        'bank_user': get_conf('BANK_USER', entorno),
        'bank_pass': get_conf('BANK_PASS', entorno),
        'simulador_username': get_conf('SIMULADOR_USERNAME', entorno),
        'simulador_password': get_conf('SIMULADOR_PASSWORD', entorno),
        'ssh_host': get_conf('SSH_HOST', entorno),
        'ssh_port': int(get_conf('SSH_PORT', entorno)),
        'ssh_user': get_conf('SSH_USER', entorno),
        'ssh_key_path': get_conf('SSH_KEY_PATH', entorno),
        'ssh_password': get_conf('SSH_PASSWORD', entorno),
        'enable_cert_pinning': get_conf('ENABLE_CERT_PINNING_FOR_BANK', entorno),
        'requests_ca_bundle': get_conf('REQUESTS_CA_BUNDLE', entorno),
        'force_insecure_ssl': get_conf('FORCE_INSECURE_SSL_FOR_BANK', entorno),
        'base_dir': get_conf('BASE_DIR', entorno),
        'use_pushtan_auto': get_conf('USE_PUSHTAN_AUTO', entorno),
        'pushtan_enabled': get_conf('PUSHTAN_ENABLED', entorno),
        'auto_authorize_transfers': get_conf('AUTO_AUTHORIZE_TRANSFERS', entorno),
        'pushtan_timeout_seconds': int(get_conf('PUSHTAN_TIMEOUT_SECONDS', entorno)),
        'pushtan_retry_interval': int(get_conf('PUSHTAN_RETRY_INTERVAL', entorno)),
        'max_transfer_retries': int(get_conf('MAX_TRANSFER_RETRIES', entorno)),
        'sepa_create_transfer_url': get_conf('SEPA_CREATE_TRANSFER_URL', entorno),
        'sepa_status_url': get_conf('SEPA_STATUS_URL', entorno),
        'sepa_details_url': get_conf('SEPA_DETAILS_URL', entorno),
        'sepa_cancel_url': get_conf('SEPA_CANCEL_URL', entorno),
        'sepa_retry_sca_url': get_conf('SEPA_RETRY_SCA_URL', entorno),
        'webhook_secret': get_conf('WEBHOOK_SECRET', entorno),
        'refresh_token': get_conf('REFRESH_TOKEN', entorno),
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
