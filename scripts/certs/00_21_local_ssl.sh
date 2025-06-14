#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

PROCESS_LOG="$SCRIPTS_DIR/logs/01_full_deploy/process_ssl.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail


LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


echo "🔐 Activando entorno virtual..." | tee -a $LOG_DEPLOY
source "$VENV_PATH/bin/activate"

PROJECT_DIR="$BASE_DIR"
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
nohup /home/markmur88/envAPP/bin/gunicorn config.wsgi:application --bind 0.0.0.0:8000 > /home/markmur88/api_bank_h2/scripts/logs/despliegue/00_21_local_ssl.log 2>&1 &
else
    echo "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443" | tee -a $LOG_DEPLOY
    echo "🔐 Certificado: $CERT_CRT" | tee -a $LOG_DEPLOY
nohup /home/markmur88/envAPP/bin/gunicorn config.wsgi:application \ > /home/markmur88/api_bank_h2/scripts/logs/despliegue/00_21_local_ssl.log 2>&1 &
      --certfile="$CERT_CRT" \
      --keyfile="$CERT_KEY" \
      --bind 0.0.0.0:8443
fi
