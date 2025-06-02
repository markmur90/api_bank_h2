#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

VPS_USER="${VPS_USER:-markmur88}"
VPS_IP="${VPS_IP:-80.78.30.242}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"

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
  rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts" "$origen/" "$VPS_USER@$VPS_IP:$destino" >> "$LOG_FILE" 2>&1
  log_ok "✅ Proyecto $nombre sincronizado en VPS ($destino)"
}

sincronizar_proyecto "$PROJECT_ROOT" "$VPS_API_DIR" "api_bank_h2"
# No sincronizamos ghost ya que descartado

