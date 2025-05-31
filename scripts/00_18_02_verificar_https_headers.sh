#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/00_18_02_verificar_https_headers/00_18_02_verificar_https_headers.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_02_verificar_https_headers/process_00_18_02_verificar_https_headers.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_02_verificar_https_headers_.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PROCESS_LOG")" "$(dirname "$LOG_DEPLOY")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

# Parametrizable: podés pasar URL por argumento
URL="${1:-https://api.coretransapi.com}"

echo "🌐 Verificando headers HTTPS en: $URL"
echo "==========================================="

curl -s -D - "$URL" --connect-timeout 5 --max-time 10 -o /dev/null | grep -Ei \
'strict-transport-security|x-frame-options|x-content-type-options|referrer-policy|x-xss-protection|content-security-policy|location'

echo "==========================================="
echo "✅ Revisión completada."
