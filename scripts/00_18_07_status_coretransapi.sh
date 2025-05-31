#!/usr/bin/env bash
set -euo pipefail

# === Parámetros ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-$HOME/.ssh/vps_njalla_nueva}"
SSH_PORT="${4:-49222}"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/status_coretransapi/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "📊 Consultando estado de coretransapi en $VPS_USER@$VPS_IP..."

ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS_USER@$VPS_IP" bash <<'EOF'
set -e

echo "📋 Estado de Supervisor:"
sudo supervisorctl status

echo -e "\n📡 Estado de Nginx:"
sudo systemctl status nginx | head -n 10

echo -e "\n🔥 Procesos Gunicorn:"
ps aux | grep gunicorn | grep -v grep
EOF

echo "✅ Consulta completada."
