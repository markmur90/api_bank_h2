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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/${SCRIPT_NAME%.sh}_.log"
mkdir -p "$(dirname "$LOG_DEPLOY")"

HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
HEROKU_APP="${1:-apibank2}"
ENV_FILE="$HEROKU_ROOT/.env.production"
PEM_PATH="$HOME/Documentos/GitHub/api_bank_h2/schemas/keys/private_key.pem"

echo -e "\033[7;30m🚀 Subiendo variables de entorno a Heroku ($HEROKU_APP)...\033[0m" | tee -a "$LOG_DEPLOY"
cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a $HEROKU_ROOT\033[0m"; exit 1; }

# 🔐 Django settings
# heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production --app "$HEROKU_APP"
heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP"

# 👤 Superusuario automático
# heroku config:set CREATE_SUPERUSER=true --app "$HEROKU_APP"
# heroku config:set DJANGO_SUPERUSER_USERNAME=markmur88 --app "$HEROKU_APP"
# heroku config:set DJANGO_SUPERUSER_EMAIL=markmur88@proton.me --app "$HEROKU_APP"
# heroku config:set DJANGO_SUPERUSER_PASSWORD=Ptf8454Jd55 --app "$HEROKU_APP"

# 🔐 Generar SECRET_KEY aleatoria
# CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
# heroku config:set DJANGO_SECRET_KEY="$CLAVE_SEGURA" --app "$HEROKU_APP"
# heroku config:set DJANGO_DEBUG=False --app "$HEROKU_APP"
# heroku config:set DJANGO_ALLOWED_HOSTS=*.herokuapp.com --app "$HEROKU_APP"

# 🔐 Claves privadas
mkdir -p keys
[[ ! -f "$PEM_PATH" ]] && {
  echo "🔐 Generando clave privada..."
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$PEM_PATH"
}

# heroku config:set PRIVATE_KEY_PATH="schemas/keys/private_key.pem" --app "$HEROKU_APP"
# heroku config:set PRIVATE_KEY_KID="$(openssl rand -hex 16)" --app "$HEROKU_APP"
PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP"

# 📤 Variables desde archivo .env.production
# echo -e "\033[7;30m📤 Cargando variables esenciales desde $ENV_FILE...\033[0m" | tee -a "$LOG_DEPLOY"

# declare -a VARS=(
#   CLIENT_ID
#   CLIENT_SECRET
#   AUTHORIZE_URL
#   TOKEN_URL
#   REDIRECT_URI
#   SCOPE
#   AUTH_URL
#   API_URL
#   OTP_URL
#   ORIGIN
#   USE_OAUTH2_UI
#   TIMEOUT
#   TIMEOUT_REQUEST
#   ACCESS_TOKEN
# )

# for VAR in "${VARS[@]}"; do
#   VALUE=$(grep "^$VAR=" "$ENV_FILE" | cut -d '=' -f2- | sed 's/^"\(.*\)"$/\1/')
#   if [[ -n "$VALUE" ]]; then
#     echo "🔧 Seteando $VAR=*****"
#     heroku config:set "$VAR=$VALUE" --app "$HEROKU_APP"
#   else
#     echo "⚠️  $VAR no definida en $ENV_FILE, se omite."
#   fi
# done
bash ./scripts/set_heroku_env.sh
heroku restart --app "$HEROKU_APP"
echo "✅ Variables configuradas y Heroku reiniciado correctamente."
