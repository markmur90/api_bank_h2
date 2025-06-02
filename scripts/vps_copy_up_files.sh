#!/usr/bin/env bash
set -e

BASE_DIR="$HOME/Documentos/GitHub/api_bank_h2/vps_config"
USER="markmur88"
IP="80.78.30.242"
KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_BASE="/etc"

echo "📁 Carpetas disponibles para subir:"
select folder in "$BASE_DIR"/*/; do
    [ -n "$folder" ] && break
    echo "❌ Selección inválida."
done

FOLDER_NAME=$(basename "$folder")

read -rp "📌 ¿Dónde querés subirla en el VPS? (ej: nginx, supervisor, tor): " SUBFOLDER
REMOTE_DEST="$REMOTE_BASE/$SUBFOLDER"

echo "📤 Subiendo $FOLDER_NAME a $REMOTE_DEST..."
scp -r -i "$KEY" -P 22 "$folder" "$USER@$IP:$REMOTE_DEST"
echo "✅ Carpeta subida con éxito."
