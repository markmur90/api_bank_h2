#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"



DJANGO_ENV=local

echo -e "\n\033[1;36m🌐 Desplegando api_bank_h2 en VPS Njalla...\033[0m" | tee -a $LOG_DEPLOY

if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
    echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m" | tee -a $LOG_DEPLOY
    bash "${SCRIPTS_DIR}/vps_instalar_dependencias.sh" >> "$LOG_DEPLOY" 2>&1
    echo -e "\033[1;36m🔁 Reintentando despliegue...\033[0m" | tee -a $LOG_DEPLOY
    if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
        echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $LOG_DEPLOY\033[0m" | tee -a $LOG_DEPLOY
        exit 1
    fi
fi
echo -e "\n\033[1;36m🔍 Verificando headers de seguridad en producción...\033[0m" | tee -a $LOG_DEPLOY
bash "$SCRIPTS_DIR/verificar_https_headers.sh" || echo -e "\033[1;31m⚠️ Error al verificar headers\033[0m"

echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m" | tee -a $LOG_DEPLOY
