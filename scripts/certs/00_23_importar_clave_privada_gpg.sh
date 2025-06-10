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

PROJECT_DIR="$BASE_DIR"
KEY_FILE="$PROJECT_DIR/jmoltke_private.asc"
LOG_DEPLOY="$PROJECT_DIR/scripts/logs/despliegue/${SCRIPT_NAME%.sh}.log"

mkdir -p "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_DEPLOY"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "❌ No se encontró el archivo de clave privada: $KEY_FILE" | tee -a "$LOG_DEPLOY"
    exit 1
fi

echo "🔐 Importando clave privada..." | tee -a "$LOG_DEPLOY"
gpg --batch --yes --import "$KEY_FILE"

# Verificar importación
KEY_ID=$(gpg --list-keys --with-colons jmoltke@protonmail.com | grep '^uid:' || true)

if [[ -n "$KEY_ID" ]]; then
  echo "✅ Clave importada correctamente para jmoltke@protonmail.com" | tee -a "$LOG_DEPLOY"
else
  echo "❌ No se pudo importar la clave." | tee -a "$LOG_DEPLOY"
  exit 1
fi

echo -e "\033[7;32m✅ Proceso finalizado.\033[0m" | tee -a "$LOG_DEPLOY"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a "$LOG_DEPLOY"
