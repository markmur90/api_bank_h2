#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$HOME/Documentos/GitHub/api_bank_h2
LOG_DIR=$PROJECT_ROOT/logs
LOG_FILE_SCRIPT=$LOG_DIR/full_deploy.log
STARTUP_LOG=$LOG_DIR/startup.log
SCRIPTS_DIR=$PROJECT_ROOT/scripts
DJANGO_ENV=local

echo -e "\n\033[1;36m🌐 Desplegando api_bank_h2 en VPS Njalla...\033[0m"

if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$STARTUP_LOG" 2>&1; then
    echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m"
    bash "${SCRIPTS_DIR}/vps_instalar_dependencias.sh" >> "$STARTUP_LOG" 2>&1
    echo -e "\033[1;36m🔁 Reintentando despliegue...\033[0m"
    if ! bash "${SCRIPTS_DIR}/21_deploy_njalla.sh" "$DJANGO_ENV" >> "$STARTUP_LOG" 2>&1; then
        echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $STARTUP_LOG\033[0m"
        exit 1
    fi
fi
echo -e "\n\033[1;36m🔍 Verificando headers de seguridad en producción...\033[0m"
bash "$SCRIPTS_DIR/verificar_https_headers.sh" || echo -e "\033[1;31m⚠️ Error al verificar headers\033[0m"

echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m"