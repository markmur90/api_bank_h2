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


cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

VPS_USER="${VPS_USER:-markmur88}"
VPS_IP="${VPS_IP:-80.78.30.242}"
SSH_KEY="${SSH_KEY:-/home/markmur88/.ssh/id_ed25519}"
APP_DIR="${VPS_API_DIR:-/home/$VPS_USER/api_bank}"
BACKUP_DIR="${BACKUP_DIR:-$BASE_DIR/backup}"
LOG_FILE="$LOG_DIR/master_run.log"
PASSPHRASE="${BACKUP_PASSPHRASE:-}"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

if [[ -z "$PASSPHRASE" ]]; then
  log_error "❌ No está definido BACKUP_PASSPHRASE en .env para cifrado."
  exit 1
fi

log_info "💾 Generando backup PostgreSQL..."

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_SQL="$BACKUP_DIR/backup_$TIMESTAMP.sql"
BACKUP_ENC="$BACKUP_DIR/backup_$TIMESTAMP.sql.enc"

mkdir -p "$BACKUP_DIR"

pg_dump --no-owner --no-acl -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" > "$BACKUP_SQL"
log_ok "✅ Backup SQL generado: $BACKUP_SQL"

log_info "🔐 Cifrando backup con AES-256..."

openssl enc -aes-256-cbc -salt -in "$BACKUP_SQL" -out "$BACKUP_ENC" -k "$PASSPHRASE"
log_ok "✅ Backup cifrado generado: $BACKUP_ENC"

log_info "📤 Transferencia de backup cifrado al VPS..."

scp -i "$SSH_KEY" -o StrictHostKeyChecking=yes -o UserKnownHostsFile="/home/markmur88/.ssh/known_hosts" \
    "$BACKUP_ENC" "$VPS_USER@$VPS_IP:$APP_DIR"

log_ok "✅ Backup cifrado transferido"

log_info "🛠️ Descifrado remoto y restauración de backup..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes -o UserKnownHostsFile="/home/markmur88/.ssh/known_hosts" "$VPS_USER@$VPS_IP" bash <<EOF
set -e
cd "$APP_DIR"
openssl enc -d -aes-256-cbc -in $(basename "$BACKUP_ENC") -out $(basename "$BACKUP_SQL") -k "$PASSPHRASE"
psql -U "$DB_USER" -d "$DB_NAME" -f $(basename "$BACKUP_SQL")
rm -f $(basename "$BACKUP_ENC") $(basename "$BACKUP_SQL")
EOF

log_ok "✅ Backup restaurado y archivos temporales eliminados en VPS"
