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

VPS_API_DIR="${VPS_API_DIR:-/home/$VPS_USER/api_bank}"
VPS_GHOST_DIR="${VPS_GHOST_DIR:-/home/$VPS_USER/ghost_recon}"

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

sincronizar_proyecto() {
  local origen="$1"
  local destino="$2"
  local nombre="$3"

  if [[ ! -d "$origen" ]]; then
    log_error "❌ Ruta local no existe: $origen"
    return 1
  fi

  log_info "🚀 Sincronizando $nombre..."
  rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/home/markmur88/.ssh/known_hosts" "$origen/" "$VPS_USER@$VPS_IP:$destino" >> "$LOG_FILE" 2>&1
  log_ok "✅ Proyecto $nombre sincronizado en VPS ($destino)"
}

sincronizar_proyecto "$BASE_DIR" "$VPS_API_DIR" "api_bank_h2"
# No sincronizamos ghost ya que descartado

