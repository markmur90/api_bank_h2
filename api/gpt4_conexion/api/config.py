# heroku/api/gpt4_conexion/api/config.py
from django.conf import settings

# Endpoint principal para crear la transferencia
TRANSFER_ENDPOINT = "/api/transferencia/"
# Endpoint para verificar OTP/TOTP
VERIFY_OTP_ENDPOINT = "/api/transferencia/verify/"

# Nota: eliminamos HEADERS estático para usar uno dinámico con JWT y TOTP