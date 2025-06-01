#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Backup de datos locales en JSON
# ===========================

# Cargar entorno desde .env
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

# Validar conexión DB
DB_NAME="${DB_NAME:-mydatabase}"
DB_USER="${DB_USER:-markmur88}"
DB_PASS="${DB_PASS:-Ptf8454Jd55}"
DB_HOST="${DB_HOST:-0.0.0.0}"

export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "💾 Generando respaldo de datos locales en JSON..."

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

if python manage.py dumpdata --indent 2 > bdd_local.json; then
  log_ok "✅ Respaldo JSON generado como 'bdd_local.json'"
else
  log_error "❌ Error al generar el respaldo JSON"
  exit 1
fi

