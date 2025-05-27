#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

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


# 🔐 Django settings

heroku config:set DJANGO_SECRET_KEY="MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw"
heroku config:set DJANGO_DEBUG=False
heroku config:set DJANGO_ALLOWED_HOSTS="tuapp.herokuapp.com,.herokuapp.com"

heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production --app apibank2
heroku config:set DISABLE_COLLECTSTATIC=1 --app apibank2

heroku config:set CREATE_SUPERUSER=true
heroku config:set DJANGO_SUPERUSER_USERNAME=markmur88
heroku config:set DJANGO_SUPERUSER_EMAIL=markmur88@proton.me
heroku config:set DJANGO_SUPERUSER_PASSWORD=Ptf8454Jd55

set -a; source .env; set +a
heroku config:set PRIVATE_KEY_PATH=keys/ecdsa_private_key.pem
heroku config:set PRIVATE_KEY_KID=keys/secret.key
heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 keys/ecdsa_private_key.pem)


# 🌐 OAuth2 - Producción
heroku config:set USE_OAUTH2_UI=True
heroku config:set CLIENT_ID="tu_client_id_asignado"
heroku config:set CLIENT_SECRET="tu_client_secret_asignado"
heroku config:set AUTHORIZE_URL="https://simulator-api.db.com/gw/oidc/authorize"
heroku config:set TOKEN_URL="https://simulator-api.db.com/gw/oidc/token"
heroku config:set REDIRECT_URI="https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/"
heroku config:set SCOPE="openid sepa:transfer"

heroku config:set OAUTH2_REDIRECT_URI="https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/"


# ⏱️ Timeouts
heroku config:set TIMEOUT_REQUEST=10


# 🌍 Entorno (si usas selector dinámico en base1.py)
heroku config:set DJANGO_ENV=production


# 🏦 API Banco
heroku config:set API_URL="https://simulator-api.db.com/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer"
heroku config:set AUTH_URL="https://simulator-api.db.com/gw/dbapi/authorization/v1/authorizations"


# 🔑 JWT (si usas `client_assertion`)
heroku config:set JWT_KID="0697a08c-2596-4545-ae01-8f0c68e93e6f"
heroku config:set JWT_KEY_PATH="schemas/keys/private_key.pem"



heroku restart --app apibank2
