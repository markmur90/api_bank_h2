#!/usr/bin/env bash
set -euo pipefail

# Variables
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
DEST_DIR="$HOME/Documentos/GitHub/api_bank_h2/scripts/vps_backup"

mkdir -p "$DEST_DIR"

# Archivos a copiar
declare -A FILES_VPS=(
  [nginx_coretransapi.conf]="/etc/nginx/sites-available/coretransapi.conf"
  [supervisor_coretransapi.conf]="/etc/supervisor/conf.d/coretransapi.conf"
  [torrc]="/etc/tor/torrc"
)

echo "📥 Copiando archivos desde VPS..."

for fname in "${!FILES_VPS[@]}"; do
  scp -i "$SSH_KEY" -P "$VPS_PORT" "$VPS_USER@$VPS_IP:${FILES_VPS[$fname]}" "$DEST_DIR/$fname"
  echo "✅ $fname copiado a $DEST_DIR"
done

echo -e "\n🎉 Todos los archivos fueron sincronizados correctamente."
