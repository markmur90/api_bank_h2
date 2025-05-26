#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -e

URL="https://apih.coretransapi.com"

echo "🌐 Verificando headers HTTPS en: $URL"
echo "==========================================="
curl -s -D - "$URL" -o /dev/null | grep -Ei 'strict-transport-security|x-frame-options|x-content-type-options|referrer-policy|x-xss-protection|content-security-policy|location'
echo "==========================================="
echo "✅ Revisión completada."
