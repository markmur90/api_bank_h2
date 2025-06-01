#!/usr/bin/env bash

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Función para autolimpieza de huella SSH
verificar_huella_ssh() {
    local host="$1"
    echo "🔍 Verificando huella SSH para $host..."
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
        echo "⚠️  Posible conflicto de huella, limpiando..."
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e


SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR"
LOG_FILE="$SCRIPT_DIR/logs/00_18_00_deploy_njalla/00_18_00_deploy_njalla.log"
PROCESS_LOG="$SCRIPT_DIR/logs/00_18_00_deploy_njalla/process_00_18_00_deploy_njalla.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/00_18_00_deploy_njalla_.log"

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

DJANGO_ENV="${1:-local}"

echo -e "\n\033[1;36m🌐 Desplegando api_bank_heroku en VPS Njalla...\033[0m" | tee -a $LOG_DEPLOY

if ! bash "${SCRIPTS_DIR}/00_18_01_01_setup_coretransact.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
    echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m" | tee -a $LOG_DEPLOY
    if ! bash "${SCRIPTS_DIR}/00_18_01_01_setup_coretransact.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
        echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $LOG_DEPLOY\033[0m" | tee -a $LOG_DEPLOY
        exit 1
    fi
fi

echo -e "\n\033[1;36m🔍 Instalando la segunda fase...\033[0m" | tee -a $LOG_DEPLOY
bash "$SCRIPTS_DIR/00_18_02_verificar_https_headers.sh" || echo -e "\033[1;31m⚠️ Error al instalar la segunda fase\033[0m"

echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m" | tee -a $LOG_DEPLOY
