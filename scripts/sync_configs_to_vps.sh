#!/usr/bin/env bash
set -euo pipefail

# Variables
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
SRC_DIR="$HOME/Documentos/GitHub/api_bank_h2/scripts/vps_backup"

# Archivos a sobrescribir
declare -A FILES_VPS=(
  [nginx_coretransapi.conf]="/etc/nginx/sites-available/coretransapi.conf"
  [supervisor_coretransapi.conf]="/etc/supervisor/conf.d/coretransapi.conf"
  [torrc]="/etc/tor/torrc"
)

echo "🚀 Subiendo y sobreescribiendo archivos en VPS..."

for fname in "${!FILES_VPS[@]}"; do
  REMOTE_PATH="${FILES_VPS[$fname]}"
  echo "→ $fname → $REMOTE_PATH"
  scp -i "$SSH_KEY" -P "$VPS_PORT" "$SRC_DIR/$fname" "$VPS_USER@$VPS_IP:/tmp/$fname"
  ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "sudo mv /tmp/$fname $REMOTE_PATH"
done

echo -e "\n✅ Archivos sobreescritos correctamente en el VPS."
