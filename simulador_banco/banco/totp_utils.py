import os
import pyotp
import qrcode
from django.conf import settings


def get_totp_secret() -> str:
    """Return the TOTP secret from settings or the environment."""
    secret = getattr(settings, "TOTP_SECRET", None)
    if not secret:
        secret = os.environ.get("TOTP_SECRET", "")
    return secret


def verify_totp(code: str) -> bool:
    """Verify a TOTP code using the shared secret."""
    try:
        totp = pyotp.TOTP(get_totp_secret())
        return totp.verify(code)
    except Exception:
        return False


def generate_totp_qr(user: str) -> str:
    """Generate a QR code for the TOTP secret and return its file path."""
    totp = pyotp.TOTP(get_totp_secret())
    uri = totp.provisioning_uri(name=user, issuer_name="BancoSeguro")
    img = qrcode.make(uri)

    # Ruta del fichero en /tmp
    path = f"/tmp/{user}_totp.png"

    # Abrir en modo binario para que save() reciba un stream válido
    with open(path, "wb") as f:
        img.save(f)

    return path