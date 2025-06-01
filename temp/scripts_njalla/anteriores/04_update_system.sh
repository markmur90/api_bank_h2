#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Actualización del sistema
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

log_info "🔄 Iniciando actualización completa del sistema..."

sudo apt-get update -y >> "$LOG_FILE" 2>&1
sudo apt-get full-upgrade -y >> "$LOG_FILE" 2>&1
sudo apt-get autoremove -y >> "$LOG_FILE" 2>&1
sudo apt-get clean >> "$LOG_FILE" 2>&1

log_ok "✅ Sistema actualizado correctamente."
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

