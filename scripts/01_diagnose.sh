#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Diagnóstico del Entorno
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

# Preparar log principal
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "🔍 Iniciando diagnóstico del entorno..."
echo -e "\n\033[1;35m🧠 Memoria RAM:\033[0m" | tee -a "$LOG_FILE"
free -h | tee -a "$LOG_FILE"

echo -e "\n\033[1;35m💾 Espacio en disco:\033[0m" | tee -a "$LOG_FILE"
df -h / | tee -a "$LOG_FILE"

echo -e "\n\033[1;35m🧮 Uso de CPU:\033[0m" | tee -a "$LOG_FILE"
top -bn1 | grep "Cpu(s)" | tee -a "$LOG_FILE"

echo -e "\n\033[1;35m🌐 Interfaces de red:\033[0m" | tee -a "$LOG_FILE"
ip a | grep inet | tee -a "$LOG_FILE"

echo -e "\n\033[1;35m🔥 Procesos activos (Python, PostgreSQL, Gunicorn):\033[0m" | tee -a "$LOG_FILE"
ps aux | grep -E 'python|postgres|gunicorn' | grep -v grep | tee -a "$LOG_FILE"

log_ok "✅ Diagnóstico completado correctamente."

