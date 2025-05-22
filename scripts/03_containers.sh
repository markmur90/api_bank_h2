#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Gestión de contenedores Docker
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

log_info "🐳 Verificando contenedores Docker activos..."

PIDS=$(docker ps -q)

if [[ -n "$PIDS" ]]; then
    docker stop $PIDS >> "$LOG_FILE" 2>&1
    echo -e "\033[7;30m🐳 Contenedores detenidos correctamente.\033[0m" | tee -a "$LOG_FILE"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
else
    echo -e "\033[7;30m🐳 No hay contenedores activos.\033[0m" | tee -a "$LOG_FILE"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
fi

log_ok "✅ Revisión de contenedores completada."

