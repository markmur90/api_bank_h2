#!/usr/bin/env bash

set -euo pipefail

# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/restart_gunicorn.log"
CERT_CRT="$AP_H2_DIR/schemas/certs/desarrollo.crt"
CERT_KEY="$AP_H2_DIR/schemas/certs/desarrollo.key"

mkdir -p "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: restart_gunicorn.sh"
  echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_DEPLOY"

echo "🔐 Activando entorno virtual..." | tee -a "$LOG_DEPLOY"
source "$VENV_PATH/bin/activate"

echo "🔁 Matando procesos Gunicorn..." | tee -a "$LOG_DEPLOY"
pkill -f "gunicorn" || echo "ℹ️ Gunicorn no estaba corriendo." | tee -a "$LOG_DEPLOY"
sleep 2

if sudo lsof -i :8443 | grep -q LISTEN; then
    echo "🧅 Puerto 8443 ocupado, se usará 8000 (sin SSL)" | tee -a "$LOG_DEPLOY"
    
    if sudo lsof -i :8000 | grep -q LISTEN; then
        echo "⚠️ Puerto 8000 en uso. Liberando..." | tee -a "$LOG_DEPLOY"
        sudo fuser -k 8000/tcp
        sleep 2
    fi

    echo "🚀 Ejecutando Gunicorn en http://0.0.0.0:8000" | tee -a "$LOG_DEPLOY"
    nohup gunicorn config.wsgi:application --bind 0.0.0.0:8000 > "$SCRIPTS_DIR/logs/despliegue/00_21_local_ssl.log" 2>&1 &
else
    echo "🌐 Ejecutando Gunicorn con SSL en https://0.0.0.0:8443" | tee -a "$LOG_DEPLOY"
    nohup gunicorn config.wsgi:application \
        --certfile="$CERT_CRT" \
        --keyfile="$CERT_KEY" \
        --bind 0.0.0.0:8443 \
        > "$SCRIPTS_DIR/logs/despliegue/00_21_local_ssl.log" 2>&1 &
fi

echo "✅ Restart completado." | tee -a "$LOG_DEPLOY"
