#!/bin/bash
# upload_to_drive.sh - Subida automática con rclone

FILE="$1"
[ ! -f "$FILE" ] && echo "Archivo no existe: $FILE" && exit 1

echo "☁️ Subiendo $FILE a Google Drive..."
rclone copy "$FILE" remote_backup:firewall_logs
echo "✅ Subida completada."
