#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/status_coretransapi/status_coretransapi.log"
PROCESS_LOG="$SCRIPT_DIR/logs/status_coretransapi/process_status_coretransapi.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/status_coretransapi_.log"

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

echo "📊 Consultando estado de coretransapi..." | tee -a "$LOG_DEPLOY"

ssh -i ~/.ssh/vps_njalla_ed25519 -p 49222 root@80.78.30.188 <<'EOF'
set -e

echo "📋 Estado de Supervisor:"
supervisorctl status

echo -e "\n📡 Estado de Nginx:"
systemctl status nginx | head -n 10

echo -e "\n🔥 Procesos Gunicorn:"
ps aux | grep gunicorn | grep -v grep

EOF

echo "✅ Tarea completada." | tee -a "$LOG_DEPLOY"
