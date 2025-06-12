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
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"
LOG_DETALLE="$SCRIPTS_DIR/logs/00_20_ssl_detalle.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_DETALLE")"

# Cabecera solo en el log maestro
{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} >> "$LOG_FILE"

# Redirigir salida detallada a log de proceso
exec > >(tee -a "$LOG_DETALLE") 2>&1

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_DETALLE"; exit 1' ERR

echo -e "🔐 Activando entorno virtual..."
# source ./venv/bin/activate

CERT_CRT="$BASE_DIR/schemas/certs/desarrollo.crt"
CERT_KEY="$BASE_DIR/schemas/certs/desarrollo.key"

echo -e "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443"
gunicorn api.wsgi:application \
    --certfile="$CERT_CRT" \
    --keyfile="$CERT_KEY" \
    --bind 0.0.0.0:8443 \
    --log-level=debug

echo -e "\n\033[1;34m🧠 Consejo:\033[0m Abre https://0.0.0.0:8000 en tu navegador y acepta el riesgo para continuar.\n" | tee -a $LOG_DEPLOY


PROJECT_DIR="$AP_H2_DIR"
cd "$PROJECT_DIR"

CERT_DIR="$PROJECT_DIR/certs"
CERT_KEY="$CERT_DIR/desarrollo.key"
CERT_CRT="$CERT_DIR/desarrollo.crt"