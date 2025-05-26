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
# heroku config:set $(cat .env.production | xargs) --app apibank2
heroku config:set DISABLE_COLLECTSTATIC=1 --app apibank2

set -a; source .env; set +a

heroku config:set PRIVATE_KEY_PATH=keys/ecdsa_private_key.pem
heroku config:set PRIVATE_KEY_KID=keys/secret.key
heroku config:set PRIVATE_KEY_B64=$(base64 -w 0 keys/ecdsa_private_key.pem)

# heroku config:set OAUTH2_REDIRECT_URI=https://apibank2-54644cdf263f.herokuapp.com/oauth2/callback/

# heroku config:set CREATE_SUPERUSER=true
# heroku config:set DJANGO_SUPERUSER_USERNAME=493069k1
# heroku config:set DJANGO_SUPERUSER_EMAIL=j.moltke@db.com
# heroku config:set DJANGO_SUPERUSER_PASSWORD=bar1588623

heroku restart --app apibank2
