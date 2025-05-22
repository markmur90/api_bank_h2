#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Despliegue automático a Heroku
# ===========================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

HEROKU_APP="apibank2-d42d7ed0d036"
HEROKU_REMOTE="heroku"
HEROKU_BRANCH="api-bank"
REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"
HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🚀 Desplegando proyecto en Heroku..."

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

log_info "Configurando variables Heroku..."

heroku config:set DJANGO_SETTINGS_MODULE=config.settings.production --app "$HEROKU_APP"
CLAVE_SEGURA=$(python3 -c "import secrets; import string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '-_') for _ in range(64)))")
heroku config:set DJANGO_SECRET_KEY="$CLAVE_SEGURA" --app "$HEROKU_APP"
heroku config:set DJANGO_DEBUG=False --app "$HEROKU_APP"
heroku config:set DJANGO_ALLOWED_HOSTS=*.herokuapp.com --app "$HEROKU_APP"
heroku config:set DB_TOKEN_URL=https://simulator-api.db.com:443/gw/dbapi/token --app "$HEROKU_APP"
heroku config:set DB_AUTH_URL=https://simulator-api.db.com:443/gw/dbapi/authorize --app "$HEROKU_APP"
heroku config:set DB_API_URL=https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer --app "$HEROKU_APP"
heroku config:set DB_SCOPE=sepa_credit_transfers --app "$HEROKU_APP"
heroku config:set API_ORIGIN=https://simulator-api.db.com --app "$HEROKU_APP"
heroku config:set TIMEOUT_REQUEST=3600 --app "$HEROKU_APP"
heroku config:set DISABLE_COLLECTSTATIC=1

log_info "🔐 Validando clave privada..."
PEM_PATH="$HOME/Documentos/GitHub/api_bank_h2/schemas/keys/ecdsa_private_key.pem"
mkdir -p keys
[[ ! -f "$PEM_PATH" ]] && openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$PEM_PATH"

heroku config:set PRIVATE_KEY_PATH="$PEM_PATH" --app "$HEROKU_APP"
heroku config:set PRIVATE_KEY_KID="$(openssl rand -hex 16)" --app "$HEROKU_APP"

log_info "📦 Preparando commit a Git..."

git add --all

if [[ -z "$(git status --porcelain)" ]]; then
  log_info "⚠️  No hay cambios para commitear."
else
  if [[ -z "${COMENTARIO_COMMIT:-}" ]]; then
    read -rp "✏️ Comentario del commit: " COMENTARIO_COMMIT
    if [[ -z "$COMENTARIO_COMMIT" ]]; then
      log_error "❌ Comentario vacío, abortando commit."
      exit 1
    fi
  else
    echo "📝 Usando comentario de commit desde master.sh"
  fi

  git commit -m "$COMENTARIO_COMMIT"
  git push origin api-bank
fi

log_info "📤 Enviando código a Heroku..."

export HEROKU_API_KEY="$HEROKU_API_KEY"
git push "$HEROKU_REMOTE" "api-bank:$HEROKU_BRANCH"

log_info "🎯 Sincronizando base de datos..."

BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"
pg_dump --no-owner --no-acl -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_FILE"

echo "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" | psql "$REMOTE_DB_URL"
pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL"

log_ok "✅ Despliegue a Heroku y sincronización completados."
