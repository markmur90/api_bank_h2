import os
from api.configuraciones_api.helpers import get_conf


def _fetch(key: str, default=None):
    """Read from environment or database configuration."""
    value = os.getenv(key)
    if value is not None:
        return value
    try:
        return get_conf(key, os.getenv("DJANGO_ENV", "production"))
    except Exception:
        return default


def load_env() -> dict:
    settings = {
        "REDIRECT_URI": _fetch("REDIRECT_URI"),
        "CLIENT_ID": _fetch("CLIENT_ID"),
        "CLIENT_SECRET": _fetch("CLIENT_SECRET"),
        "ORIGIN": _fetch("ORIGIN"),
        "TOKEN_URL": _fetch("TOKEN_URL"),
        "OTP_URL": _fetch("OTP_URL"),
        "AUTH_URL": _fetch("AUTH_URL"),
        "API_URL": _fetch("API_URL"),
        "AUTHORIZE_URL": _fetch("AUTHORIZE_URL"),
        "SCOPE": _fetch("SCOPE"),
        "TIMEOUT": int(_fetch("TIMEOUT")),
        "TIMEOUT_REQUEST": int(_fetch("TIMEOUT_REQUEST")),
        "DNS_BANCO": _fetch("DNS_BANCO"),
        "DOMINIO_BANCO": _fetch("DOMINIO_BANCO"),
        "RED_SEGURA_PREFIX": _fetch("RED_SEGURA_PREFIX"),
        "MOCK_PORT": int(_fetch("MOCK_PORT")),
        "SIMULADOR_API_URL": _fetch("SIMULADOR_API_URL"),
        "SIMULADOR_LOGIN_URL": _fetch("SIMULADOR_LOGIN_URL"),
        "SIMULADOR_VERIFY_URL": _fetch("SIMULADOR_VERIFY_URL"),
        "SIMULADOR_USERNAME": _fetch("SIMULADOR_USERNAME"),
        "SIMULADOR_PASSWORD": _fetch("SIMULADOR_PASSWORD"),
        "BASE_URL": _fetch("BASE_URL"),
        "STATUS_PATH": _fetch("STATUS_PATH"),
        "TRANSFER_URL": _fetch("TRANSFER_URL"),
        "ALLOW_FAKE_BANK": _fetch("ALLOW_FAKE_BANK"),
        
        # URLs adicionales del .env.production
        "TOKEN_ENDPOINT": _fetch("TOKEN_ENDPOINT"),
        "CHALLENGE_URL": _fetch("CHALLENGE_URL"),
        "STATUS_URL": _fetch("STATUS_URL"),
        "VERIFY_URL": _fetch("VERIFY_URL"),
        "TOKEN_PATH": _fetch("TOKEN_PATH"),
        "AUTH_PATH": _fetch("AUTH_PATH"),
        "SEND_PATH": _fetch("SEND_PATH"),
        "VERIFY_PATH": _fetch("VERIFY_PATH"),
        
        # Credenciales bancarias
        "BANK_USER": _fetch("BANK_USER"),
        "BANK_PASS": _fetch("BANK_PASS"),
        
        # Configuración SSH
        "SSH_HOST": _fetch("SSH_HOST"),
        "SSH_PORT": int(_fetch("SSH_PORT")),
        "SSH_USER": _fetch("SSH_USER"),
        "SSH_KEY_PATH": _fetch("SSH_KEY_PATH"),
        "SSH_PASSWORD": _fetch("SSH_PASSWORD"),
        
        # Configuración SSL
        "ENABLE_CERT_PINNING_FOR_BANK": _fetch("ENABLE_CERT_PINNING_FOR_BANK"),
        "REQUESTS_CA_BUNDLE": _fetch("REQUESTS_CA_BUNDLE"),
        "FORCE_INSECURE_SSL_FOR_BANK": _fetch("FORCE_INSECURE_SSL_FOR_BANK"),
        "BANK_CERT_PIN_SHA256": _fetch("BANK_CERT_PIN_SHA256"),
        "BASE_DIR": _fetch("BASE_DIR"),
        
        # Configuración Pushtan
        "USE_PUSHTAN_AUTO": _fetch("USE_PUSHTAN_AUTO"),
        "PUSHTAN_ENABLED": _fetch("PUSHTAN_ENABLED"),
        "AUTO_AUTHORIZE_TRANSFERS": _fetch("AUTO_AUTHORIZE_TRANSFERS"),
        "PUSHTAN_TIMEOUT_SECONDS": int(_fetch("PUSHTAN_TIMEOUT_SECONDS")),
        "PUSHTAN_RETRY_INTERVAL": int(_fetch("PUSHTAN_RETRY_INTERVAL")),
        "MAX_TRANSFER_RETRIES": int(_fetch("MAX_TRANSFER_RETRIES")),
        
        # URLs SEPA
        "SEPA_CREATE_TRANSFER_URL": _fetch("SEPA_CREATE_TRANSFER_URL"),
        "SEPA_STATUS_URL": _fetch("SEPA_STATUS_URL"),
        "SEPA_DETAILS_URL": _fetch("SEPA_DETAILS_URL"),
        "SEPA_CANCEL_URL": _fetch("SEPA_CANCEL_URL"),
        "SEPA_RETRY_SCA_URL": _fetch("SEPA_RETRY_SCA_URL"),

        "ACCESS_TOKEN": _fetch("ACCESS_TOKEN"),
        "JWT_SIGNING_KEY": _fetch("JWT_SIGNING_KEY"),
        "JWT_VERIFYING_KEY": _fetch("JWT_VERIFYING_KEY"),
        

    }

    settings["OAUTH2"] = {
        
        "REDIRECT_URI": settings["REDIRECT_URI"],
        "CLIENT_ID": settings["CLIENT_ID"],
        "CLIENT_SECRET": settings["CLIENT_SECRET"],
        "ACCESS_TOKEN": settings["ACCESS_TOKEN"],
        "ORIGIN": settings["ORIGIN"],
        "OTP_URL": settings["OTP_URL"],
        "AUTH_URL": settings["AUTH_URL"],
        "API_URL": settings["API_URL"],
        "TOKEN_URL": settings["TOKEN_URL"],
        "AUTHORIZE_URL": settings["AUTHORIZE_URL"],
        "SCOPE": settings["SCOPE"],
        "TIMEOUT_REQUEST": settings["TIMEOUT_REQUEST"],
        "DNS_BANCO": settings["DNS_BANCO"],
        "DOMINIO_BANCO": settings["DOMINIO_BANCO"],
        "RED_SEGURA_PREFIX": settings["RED_SEGURA_PREFIX"],
        "TIMEOUT": settings["TIMEOUT"],
        "MOCK_PORT": settings["MOCK_PORT"],
    }
    return settings