#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/check_ssl_ports/check_ssl_ports.log"
PROCESS_LOG="$SCRIPT_DIR/logs/check_ssl_ports/process_check_ssl_ports.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/check_ssl_ports_.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"
mkdir -p "$(dirname "$LOG_DEPLOY")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

echo "🔎 Verificando certificados SSL y puertos abiertos..." | tee -a "$LOG_DEPLOY"

ssh -i ~/.ssh/vps_njalla_ed25519 -p 49222 root@80.78.30.188 <<'EOF'
set -e

echo "🔐 Certificados SSL instalados:"
ls -l /etc/letsencrypt/live/apih.coretransapi.com/

echo -e "\n🌍 Verificación de puertos abiertos (80, 443, 49222):"
for PORT in 80 443 49222; do
    echo -n "Puerto $PORT: "
    ss -tuln | grep ":$PORT" && echo "🟢 Abierto" || echo "🔴 Cerrado"
done

EOF

echo "✅ Tarea completada." | tee -a "$LOG_DEPLOY"
