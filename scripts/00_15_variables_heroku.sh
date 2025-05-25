#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./logs/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"

echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m" | tee -a $LOG_DEPLOY
cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
# Configurar variable DJANGO_SETTINGS_MODULE
echo -e "\033[7;36m🔧 Configurando DJANGO_SETTINGS_MODULE en Heroku...\033[0m" | tee -a $LOG_DEPLOY
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
CLIENT_ID="766ae693-6297-47ea-b825-fd3d07dcf9b6" \
CLIENT_SECRET="CCGiHIEQZmMjxS8JXCzt8a8nSKLXKDoVy3a61ZWD2jIaFfcDMq7ekmsLaog3fjpzqVpXj-4piqSoiln7dqKwuQ" \
ORIGIN="https://api.db.com" \
TOKEN_URL="https://simulator-api.db.com:443/gw/dbapi/token" \
OTP_URL="https://simulator-api.db.com:443/gw/dbapi/others/onetimepasswords/v2/single" \
AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/authorize" \
API_URL="https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer" \
AUTHORIZE_URL="https://simulator-api.db.com:443/gw/oidc/authorize" \
SCOPE="sepa_credit_transfers" \
TIMEOUT_REQUEST=3600 \
JWT_SIGNING_KEY="app/keys/secret.key" \
JWT_VERIFYING_KEY="app/keys/secret.key" \
--app apibank2

heroku restart --app apibank2
