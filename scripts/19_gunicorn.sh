#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Lanzamiento de Gunicorn, Honeypot y Livereload
# ===========================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

# Preparar logs
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

# Definir URLs locales
URL_LOCAL="http://localhost:5000"
URL_GUNICORN="http://127.0.0.1:8001"

# Puertos que podrían estar ocupados
PUERTOS=(8001 5000 35729)

liberar_puertos() {
  for port in "${PUERTOS[@]}"; do
    if lsof -i :"$port" > /dev/null 2>&1; then
      echo -e "\033[1;33m🔌 Liberando puerto $port...\033[0m"
      kill "$(lsof -t -i :"$port")" 2>/dev/null || true
    fi
  done
}

limpiar_y_salir() {
  echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m"
  pkill -f "gunicorn" || true
  pkill -f "honeypot.py" || true
  pkill -f "livereload" || true
  pkill -f "firefox" || true
  liberar_puertos
  echo -e "\033[1;32m✅ Servicios detenidos.\033[0m"
  echo -e "$LOGO_SEP\n"
  exit 0
}

trap limpiar_y_salir SIGINT

log_info "🚀 Iniciando Gunicorn, Honeypot y Livereload..."

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

python manage.py collectstatic --noinput >> "$LOG_FILE" 2>&1

export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:5432/${DB_NAME}"

nohup "$VENV_DIR/bin/gunicorn" config.wsgi:application --workers 3 --bind 127.0.0.1:8001 --keep-alive 2 \
  > "$LOG_DIR/gunicorn_api.log" 2>&1 < /dev/null &

nohup python honeypot.py > "$LOG_DIR/honeypot.log" 2>&1 < /dev/null &

nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ \
  > "$LOG_DIR/livereload.log" 2>&1 < /dev/null &

sleep 3

firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" &

log_ok "✅ Servicios activos. Pulsa Ctrl+C para detener."
echo -e "$LOGO_SEP\n"

while true; do sleep 3; done
