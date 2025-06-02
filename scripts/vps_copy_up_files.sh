#!/usr/bin/env bash
set -euo pipefail

echo "📤 Subiendo archivos actualizados al VPS..."

VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"

LOCAL_DIR="$HOME/Documentos/GitHub/api_bank_heroku/scripts/vps_backup"

scp -i "$SSH_KEY" -P "$VPS_PORT" \
  "$LOCAL_DIR/nginx_coretransapi.conf" \
  "$LOCAL_DIR/supervisor_coretransapi.conf" \
  "$LOCAL_DIR/torrc" \
  "$VPS_USER@$VPS_IP:/tmp"

echo "✅ Archivos subidos al VPS (/tmp)"
