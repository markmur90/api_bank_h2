#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Carga de datos locales (fixtures)
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

log_info "📂 Iniciando carga de fixture local (bdd_local.json)..."

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

if [[ -f "bdd_local.json" ]]; then
  python manage.py loaddata bdd_local.json >> "$LOG_FILE" 2>&1
  log_ok "✅ Datos cargados correctamente desde bdd_local.json"
else
  log_error "❌ Archivo bdd_local.json no encontrado en $PROJECT_ROOT"
  exit 1
fi

