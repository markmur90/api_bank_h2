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
BACKUP_DIR="$PROJECT_DIR/backup/sql"
LOG_FILE="$SCRIPTS_DIR/logs/respaldo_local_cifrado.log"

DB_NAME="mydatabase"
DB_USER="markmur88"
KEY_EMAIL="jmoltke@protonmail.com"
GPG_PUBLIC_KEY="$PROJECT_DIR/gpg_keys/jmoltke_public.asc"

# 💾 Archivos
PLAIN="$BACKUP_DIR/backup_local.sql"
CIFRADO="$PLAIN.gpg"

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# 🎯 Validación GPG
if ! gpg --list-keys "$KEY_EMAIL" &>/dev/null; then
  echo "ℹ️ Importando clave pública $KEY_EMAIL..."
  gpg --import "$GPG_PUBLIC_KEY"
fi

{
echo "📅 Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "📦 Backup local → $CIFRADO"
echo "════════════════════════════════════════"
echo -e "\033[1;32m🚀 Dump de PostgreSQL...\033[0m"
pg_dump --no-owner --no-acl -U "$DB_USER" "$DB_NAME" > "$PLAIN"

echo "🔐 Cifrando con GPG..."
gpg --yes --batch --output "$CIFRADO" --encrypt --recipient "$KEY_EMAIL" "$PLAIN"

echo -e "\033[1;32m✅ Backup cifrado en: $CIFRADO\033[0m"
} | tee -a "$LOG_FILE"
