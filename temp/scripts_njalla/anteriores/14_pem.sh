#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Generación de claves PEM y JWKS (OAuth2)
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

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🔐 Generando claves PEM y JWKS..."

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

if python manage.py genkey >> "$LOG_FILE" 2>&1; then
  log_ok "✅ Claves PEM y JWKS generadas correctamente."
else
  log_error "❌ Error al generar claves con 'manage.py genkey'"
  exit 1
fi

