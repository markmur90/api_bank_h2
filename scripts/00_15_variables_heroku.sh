#!/usr/bin/env bash
set -euo pipefail

HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"

echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m"
cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
# Configurar variable DJANGO_SETTINGS_MODULE
echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m"
# CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")

heroku config:set \
DJANGO_ENV=production \
DISABLE_COLLECTSTATIC=1 \
DEBUG=False \
SECRET_KEY="L3hesOa21ZGRsk0TsVvKMI6kWuv8d-ZAGIfP87i4Hv0" \
SESSION_COOKIE_SECURE=True \
CSRF_COOKIE_SECURE=True \
SECURE_SSL_REDIRECT=True \
ALLOWED_HOSTS=apibank2-d42d7ed0d036.herokuapp.com,api.coretransapi.com \
PRIVATE_KEY_KID="98a7f5c0-a4fb-4a1a-8b1d-ce5437e14a08" \
PRIVATE_KEY_PATH=/app/schemas/keys/ecdsa_private_key.pem \
CLIENT_ID="tu-client-id-heroku" \
CLIENT_SECRET="tu-client-secret-heroku" \
ORIGIN="https://api.db.com" \
TOKEN_URL="https://simulator-api.db.com:443/gw/dbapi/token" \
OTP_URL="REEMPLAZAR_OTP_URL" \
AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/authorize" \
API_URL="https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer" \
AUTHORIZE_URL="REEMPLAZAR_AUTHORIZE_URL" \
SCOPE="sepa_credit_transfers" \
TIMEOUT_REQUEST=3600 \
ACCESS_TOKEN="REEMPLAZAR_ACCESS_TOKEN" \
JWT_SIGNING_KEY="REEMPLAZAR_JWT_SIGNING_KEY" \
JWT_VERIFYING_KEY="REEMPLAZAR_JWT_VERIFYING_KEY" \
--app apibank2

heroku restart --app apibank2
