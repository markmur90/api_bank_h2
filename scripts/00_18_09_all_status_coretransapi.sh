#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_09_all_status_coretransapi/00_18_09_all_status_coretransapi.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_09_all_status_coretransapi/process_00_18_09_all_status_coretransapi.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_09_all_status_coretransapi_.log"

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



#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/status/all_status_master.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

# Ejecutar cada chequeo remoto y loguear separado
echo -e "\n📋 [1/3] Supervisor, nginx y gunicorn" | tee -a "$LOG_FILE"
bash ./status_coretransapi.sh 2>&1 | tee -a "$LOG_FILE"

echo -e "\n🔐 [2/3] Certificados SSL y puertos" | tee -a "$LOG_FILE"
bash ./check_ssl_ports.sh 2>&1 | tee -a "$LOG_FILE"

echo -e "\n✅ Todo verificado correctamente." | tee -a "$LOG_FILE"