#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Notificación final de despliegue
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
LOG_FILE="${LOG_DIR}/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }

log_info "📢 Enviando notificación final..."

# Definir URLs conocidas
URL_LOCAL="http://localhost:5000"
URL_HEROKU="https://${PROJECT_NAME}.herokuapp.com"

# Variables opcionales
COMENTARIO_COMMIT="${COMENTARIO_COMMIT:-Sin comentario}"
BACKUP_FILE="${BACKUP_FILE:-<no backup file>}"

notify-send "✅ Despliegue Finalizado" \
"API ${PROJECT_NAME} disponible en:
🌐 Local:  $URL_LOCAL
🌐 Heroku: $URL_HEROKU

📦 Último backup: $BACKUP_FILE
📝 Commit: $COMENTARIO_COMMIT

📄 Log: $LOG_FILE" --icon=utilities-terminal

log_info "✅ Notificación mostrada con notify-send."

