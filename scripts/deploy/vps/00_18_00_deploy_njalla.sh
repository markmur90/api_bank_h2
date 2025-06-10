#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"
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
        ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e -x


SCRIPT_NAME="$(basename "$0")"

SCRIPTS_DIR="$SCRIPTS_DIR"
LOG_FILE="$SCRIPTS_DIR/logs/deploy_njalla.log"
PROCESS_LOG="$SCRIPTS_DIR/logs/deploy_njalla.log"
LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/deploy_njalla_.log"

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

if ! bash "/home/markmur88/api_bank_h2/scripts/deploy/vps/vps_backup/00_18_01_01_setup_coretransact_root_FASE1.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
    echo -e "\033[1;31m⚠️ Fallo en el primer intento de deploy. Ejecutando instalación de dependencias...\033[0m" | tee -a $LOG_DEPLOY
    if ! bash "/home/markmur88/api_bank_h2/scripts/deploy/vps/vps_backup/00_18_01_01_setup_coretransact_root_FASE1.sh" "$DJANGO_ENV" >> "$LOG_DEPLOY" 2>&1; then
        echo -e "\033[1;31m❌ Fallo final en despliegue remoto. Consulta logs en $LOG_DEPLOY\033[0m" | tee -a $LOG_DEPLOY
        exit 1
    fi
fi

echo -e "\n\033[1;36m🔍 Instalando la segunda fase...\033[0m" | tee -a $LOG_DEPLOY
bash "/home/markmur88/api_bank_h2/scripts/deploy/vps/vps_backup/00_18_01_01_setup_coretransact_root_FASE2.sh" || echo -e "\033[1;31m⚠️ Error al instalar la segunda fase\033[0m"

echo -e "\033[1;32m✅ Despliegue remoto al VPS completado.\033[0m" | tee -a $LOG_DEPLOY
