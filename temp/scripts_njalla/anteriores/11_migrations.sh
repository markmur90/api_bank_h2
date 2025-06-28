#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Generación y aplicación de migraciones Django
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

log_info "🔄 Iniciando limpieza de migraciones antiguas..."

cd "$PROJECT_ROOT"

# Activar entorno virtual
source "$VENV_DIR/bin/activate"

# Eliminar caché y migraciones previas
find . -path "*/__pycache__" -type d -exec rm -rf {} + >> "$LOG_FILE"
find . -name "*.pyc" -delete >> "$LOG_FILE"
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete >> "$LOG_FILE"
find . -path "*/migrations/*.pyc" -delete >> "$LOG_FILE"

log_info "⚙️ Generando nuevas migraciones..."
python manage.py makemigrations >> "$LOG_FILE" 2>&1

log_info "⏳ Aplicando migraciones..."
python manage.py migrate >> "$LOG_FILE" 2>&1

log_ok "✅ Migraciones aplicadas correctamente."

