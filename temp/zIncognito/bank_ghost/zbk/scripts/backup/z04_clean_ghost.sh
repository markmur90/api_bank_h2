#!/bin/bash

echo "🧼 Limpiando entorno Ghost Recon..."

PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"

[ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo "🗑️ Socket eliminado."

find "$LOG_DIR" -type f -name 'cron_output_*.log' -delete && echo "🧹 Logs temporales eliminados."
find "$LOG_DIR" -type f -name 'cron_ghost.log' -exec truncate -s 0 {} \; && echo "🧾 Log principal truncado."

pkill -u $(whoami) -f gunicorn 2>/dev/null
pkill -u $(whoami) -f ghost_recon_ultimate.py 2>/dev/null
pkill -u $(whoami) -f cron_wrapper.py 2>/dev/null

echo "✅ Limpieza completa."


# =========================== z04 ===========================