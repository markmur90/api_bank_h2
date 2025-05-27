#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
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
heroku config:set DJANGO_ALLOWED_HOSTS="apibank2-54644cdf263f.herokuapp.com,.herokuapp.com,apih.coretransapi.com"

heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production --app apibank2
heroku config:set DISABLE_COLLECTSTATIC=1 --app apibank2

heroku config:set CREATE_SUPERUSER=true
heroku config:set DJANGO_SUPERUSER_USERNAME=markmur88
heroku config:set DJANGO_SUPERUSER_EMAIL=markmur88@proton.me
heroku config:set DJANGO_SUPERUSER_PASSWORD=Ptf8454Jd55

set -a; source .env; set +a
heroku config:set PRIVATE_KEY_PATH=schemas/keys/private_key.pem
heroku config:set PRIVATE_KEY_KID=schemas/keys/secret.key
heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 schemas/keys/private_key.pem)


# 🌐 OAuth2 - Producción
heroku config:set USE_OAUTH2_UI=False

heroku config:set CLIENT_ID="7c1e2c53-8cc3-4ea0-bdd6-b3423e76adc7"
heroku config:set CLIENT_SECRET="L88pwGelUZ5EV1YpfOG3e_r24M8YQ40-Gaay9HC4vt4RIl-Jz2QjtmcKxY8UpOWUInj9CoUILPBSF-H0QvUQqw"
heroku config:set CLIENT_SECRET="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzQ0Njk1MTE5LCJpYXQiOjE3NDQ2OTMzMTksImp0aSI6ImUwODBhMTY0YjZlZDQxMjA4NzdmZTMxMDE0YmE4Y2Y5IiwidXNlcl9pZCI6MX0.432cmStSF3LXLG2j2zLCaLWmbaNDPuVm38TNSfQclMg"


heroku config:set AUTHORIZE_URL="https://simulator-api.db.com/gw/oidc/authorize"
heroku config:set TOKEN_URL="https://simulator-api.db.com/gw/oidc/token"
heroku config:set SCOPE="openid sepa:transfer sepa_credit_transfers"

heroku config:set ORIGIN="https://apibank2-54644cdf263f.herokuapp.com"
heroku config:set REDIRECT_URI="https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/"
heroku config:set OAUTH2_REDIRECT_URI="https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/"


# ⏱️ Timeouts
heroku config:set TIMEOUT_REQUEST=3600
heroku config:set TIMEOUT=3600


# 🌍 Entorno (si usas selector dinámico en base1.py)
heroku config:set DJANGO_ENV=production


# 🏦 API Banco
heroku config:set API_URL="https://simulator-api.db.com/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer"
heroku config:set AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/others/transactionAuthorization/v1/challenges"
heroku config:set OTP_URL="https://simulator-api.db.com:443/gw/dbapi/others/onetimepasswords/v2/single"


# 🔑 JWT (si usas `client_assertion`)
heroku config:set JWT_KID="98a7f5c0-a4fb-4a1a-8b1d-ce5437e14a08"
heroku config:set JWT_KEY_PATH="schemas/keys/private_key.pem"



heroku restart --app apibank2
