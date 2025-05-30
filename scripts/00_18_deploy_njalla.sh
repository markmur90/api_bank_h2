#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"



DJANGO_ENV=local

echo -e "\n\033[1;36m🌐 Desplegando api_bank_heroku en VPS Njalla...\033[0m" | tee -a $LOG_DEPLOY

if ! bash "${SCRIPTS_DIR}/00_18_01_setup_coretransact.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
    echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m" | tee -a $LOG_DEPLOY
    if ! bash "${SCRIPTS_DIR}/00_18_01_setup_coretransact.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
        echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $LOG_DEPLOY\033[0m" | tee -a $LOG_DEPLOY
        exit 1
    fi
fi
echo -e "\n\033[1;36m🔍 Verificando headers de seguridad en producción...\033[0m" | tee -a $LOG_DEPLOY
bash "$SCRIPTS_DIR/00_18_02_verificar_https_headers.sh" || echo -e "\033[1;31m⚠️ Error al verificar headers\033[0m"

echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m" | tee -a $LOG_DEPLOY
