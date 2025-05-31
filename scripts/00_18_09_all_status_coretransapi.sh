#!/usr/bin/env bash
set -euo pipefail

# === Parámetros comunes a todos los sub-scripts ===
VPS_USER="${1:-markmur88}"
VPS_IP="${2:-80.78.30.242}"
SSH_KEY="${3:-$HOME/.ssh/vps_njalla_nueva}"
SSH_PORT="${4:-49222}"
DOMAIN="${5:-api.coretransapi.com}"
PUERTOS="${6:-80 443 49222}"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/status/all_status_master.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

# === Rutas absolutas de scripts hijos ===
STATUS_SCRIPT="$SCRIPT_DIR/00_18_07_status_coretransapi.sh"
SSL_SCRIPT="$SCRIPT_DIR/00_18_08_check_ssl_ports.sh"

if [[ ! -x "$STATUS_SCRIPT" ]]; then
    echo "❌ No se encontró $STATUS_SCRIPT o no es ejecutable"
    exit 1
fi

if [[ ! -x "$SSL_SCRIPT" ]]; then
    echo "❌ No se encontró $SSL_SCRIPT o no es ejecutable"
    exit 1
fi

echo -e "\n📋 [1/2] Estado de coretransapi (Supervisor, Nginx, Gunicorn)"
bash "$STATUS_SCRIPT" "$VPS_USER" "$VPS_IP" "$SSH_KEY" "$SSH_PORT"

echo -e "\n🔐 [2/2] Certificados SSL y puertos escuchando"
bash "$SSL_SCRIPT" "$VPS_USER" "$VPS_IP" "$SSH_KEY" "$SSH_PORT" "$DOMAIN" "$PUERTOS"

echo -e "\n✅ Todo verificado correctamente."
