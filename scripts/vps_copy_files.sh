#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURACIÓN VPS ===
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"

# === RUTA LOCAL DE DESTINO ===
DEST_DIR="$HOME/Documentos/GitHub/api_bank_h2/scripts/vps_backup"
mkdir -p "$DEST_DIR"

# === ARCHIVOS A COPIAR ===
declare -A FILES_TO_COPY=(
  ["/etc/nginx/sites-available/coretransapi.conf"]="nginx_coretransapi.conf"
  ["/etc/supervisor/conf.d/coretransapi.conf"]="supervisor_coretransapi.conf"
  ["/etc/tor/torrc"]="torrc"
)

echo "📦 Copiando archivos desde el VPS..."

for REMOTE_PATH in "${!FILES_TO_COPY[@]}"; do
    LOCAL_NAME="${FILES_TO_COPY[$REMOTE_PATH]}"
    echo "→ $REMOTE_PATH"
    ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "sudo cat '$REMOTE_PATH'" > "$DEST_DIR/$LOCAL_NAME"
done

echo "✅ Archivos guardados en: $DEST_DIR"
