#!/usr/bin/env bash
set -e

USER="markmur88"
IP="80.78.30.242"
KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_BASE="/etc"

read -rp "📌 ¿Qué carpeta del VPS querés copiar? (ej: nginx, tor, supervisor): " REMOTE_FOLDER
REMOTE_PATH="$REMOTE_BASE/$REMOTE_FOLDER"

DEST_DIR="$HOME/Documentos/GitHub/api_bank_h2/vps_config"
echo "📁 Carpetas locales disponibles para guardar:"
select local_target in "$DEST_DIR"/*/; do
    [ -n "$local_target" ] && break
    echo "❌ Selección inválida."
done

echo "📥 Copiando $REMOTE_PATH a $local_target..."
scp -r -i "$KEY" -P 22 "$USER@$IP:$REMOTE_PATH" "$local_target"
echo "✅ Carpeta copiada exitosamente."
