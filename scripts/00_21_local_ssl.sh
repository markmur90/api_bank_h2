#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


echo "🔐 Activando entorno virtual..." | tee -a $LOG_DEPLOY
source "/home/markmur88/Documentos/Entorno/envAPP/bin/activate"

PROJECT_DIR="/home/markmur88/Documentos/GitHub/api_bank_h2"
cd "$PROJECT_DIR"

CERT_CRT="$PROJECT_DIR/schemas/certs/desarrollo.crt"
CERT_KEY="$PROJECT_DIR/schemas/certs/desarrollo.key"

if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "⚠️ Certificados no encontrados. Generando nuevos..." | tee -a $LOG_DEPLOY
    mkdir -p certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=Local Dev/OU=Dev/CN=0.0.0.0"
fi

if sudo lsof -i :8443 | grep -q LISTEN; then
    echo "🧅 Puerto 8443 ya está en uso (probablemente Nginx)." | tee -a $LOG_DEPLOY
    
    if sudo lsof -i :8000 | grep -q LISTEN; then
        echo "⚠️ Puerto 8000 en uso. Liberando..." | tee -a $LOG_DEPLOY
        sudo fuser -k 8000/tcp
        sleep 2
    fi

    echo "🚀 Ejecutando Gunicorn como backend en http://0.0.0.0:8000" | tee -a $LOG_DEPLOY
nohup gunicorn config.wsgi:application --bind 0.0.0.0:8000 > scripts/logs/01_full_deploy/full_deploy.log 2>&1 &
else
    echo "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443" | tee -a $LOG_DEPLOY
    echo "🔐 Certificado: $CERT_CRT" | tee -a $LOG_DEPLOY
nohup gunicorn config.wsgi:application \ > scripts/logs/01_full_deploy/full_deploy.log 2>&1 &
      --certfile="$CERT_CRT" \
      --keyfile="$CERT_KEY" \
      --bind 0.0.0.0:8443
fi