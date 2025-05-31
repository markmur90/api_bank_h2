#!/usr/bin/env bash
set -euo pipefail

# === Parámetros ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-$HOME/.ssh/vps_njalla_nueva}"
SSH_PORT="${4:-49222}"
DOMAIN="${5:-api.coretransapi.com}"
PUERTOS="${6:-80 443 49222}"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/check_ssl_ports/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo "📄 Script: $SCRIPT_NAME"
echo "🔍 Verificando SSL y puertos abiertos en $VPS_USER@$VPS_IP..."

ssh -i "$SSH_KEY" -p "$SSH_PORT" "$VPS_USER@$VPS_IP" bash <<EOF
set -e

echo "🔐 Certificados SSL para $DOMAIN:"
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    ls -l "/etc/letsencrypt/live/$DOMAIN"
else
    echo "❌ Directorio SSL no encontrado: /etc/letsencrypt/live/$DOMAIN"
fi

echo -e "\n🌐 Verificación de puertos:"
for PORT in $PUERTOS; do
    echo -n "Puerto $PORT: "
    ss -tuln | grep ":$PORT" &>/dev/null && echo "🟢 Abierto" || echo "🔴 Cerrado"
done
EOF

echo "✅ Revisión completada."
