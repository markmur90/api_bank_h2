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

LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/${SCRIPT_NAME%.sh}.log"
PROCESS_LOG="$SCRIPTS_DIR/logs/01_full_deploy/process_ssl.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"

# Limpiar log de proceso
> "$PROCESS_LOG"

{
  echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "📄 Script: $SCRIPT_NAME"
  echo "═══════════════════════════════════════════"
} >> "$LOG_FILE"
{
  echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "📄 Script: $SCRIPT_NAME"
  echo "═══════════════════════════════════════════"
} >> "$PROCESS_LOG"

trap '{
  echo "";
  echo "❌ Error en línea $LINENO: \"$BASH_COMMAND\"";
  echo "Abortando ejecución.";
} >> "$LOG_FILE" >> "$PROCESS_LOG"; exit 1' ERR

{
#   echo "🔐 Activando entorno virtual..."
#   source "$SCRIPTS_DIR/../../venv/bin/activate"

  PROJECT_DIR="$AP_H2_DIR"

  cd "$PROJECT_DIR"

  CERT_DIR="$PROJECT_DIR/certs"
  CERT_KEY="$CERT_DIR/desarrollo.key"
  CERT_CRT="$CERT_DIR/desarrollo.crt"

  if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "❌ Certificado no encontrado: $CERT_CRT o $CERT_KEY"
    exit 1
  fi

  echo "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443"

  cd "$SCRIPTS_DIR/.." || exit 1

  nohup gunicorn config.wsgi:application \
    --certfile="$CERT_CRT" \
    --keyfile="$CERT_KEY" \
    --bind 0.0.0.0:8443 \
    --workers 3 \
    --timeout 300 \
    --log-file - >> "$PROCESS_LOG" 2>&1 &
} >> "$PROCESS_LOG" 2>&1
