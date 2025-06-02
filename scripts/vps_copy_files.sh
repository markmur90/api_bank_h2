#!/usr/bin/env bash
set -euo pipefail

USER="markmur88"
IP="80.78.30.242"
KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_BASE="/etc"
DEST_DIR="$HOME/Documentos/GitHub/api_bank_h2/vps_config"
LOG_DIR="$DEST_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/download_$(date '+%Y%m%d_%H%M%S').log"

read -rp "📌 ¿Qué carpeta del VPS querés copiar? (ej: nginx, tor, supervisor): " REMOTE_FOLDER
REMOTE_PATH="$REMOTE_BASE/$REMOTE_FOLDER"

echo "📁 Carpetas locales disponibles para guardar:"
select local_target in "$DEST_DIR"/*/; do
    [ -n "$local_target" ] && break
    echo "❌ Selección inválida."
done

{
    echo "=== DOWNLOAD - $(date) ==="
    echo "📂 Desde VPS: $REMOTE_PATH"
    echo "📥 Hacia local: $local_target"
    scp -r -i "$KEY" -P 22 "$USER@$IP:$REMOTE_PATH" "$local_target"
    echo "✅ Carpeta copiada exitosamente."
} | tee "$LOG_FILE"
