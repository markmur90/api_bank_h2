#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./logs/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -e

VPS_USER="markmur88"
VPS_IP="80.78.30.188"

echo "📡 Conectando a VPS $VPS_USER@$VPS_IP..."
ssh "$VPS_USER@$VPS_IP" bash << 'EOF'
echo "🩺 Uptime:"
uptime
echo ""

echo "🧠 Memoria:"
free -h
echo ""

echo "🗂 Espacio en disco:"
df -h /
echo ""

echo "🔥 Procesos Gunicorn:"
ps aux | grep gunicorn | grep -v grep
echo ""

echo "🌐 Estado Nginx y Supervisor:"
sudo systemctl status nginx | grep Active
sudo systemctl status supervisor | grep Active
EOF
