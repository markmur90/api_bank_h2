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

set -euo pipefail


SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail



LOG_BACKUP="$SCRIPTS_DIR/logs/backup/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_BACKUP)"




PROJECT_BASE_DIR="$HOME"
BACKUP_DIR="$PROJECT_BASE_DIR/backup/zip"

DATE=$(date +"%Y%m%d_%H%M%S")
DATE_SHORT=$(date +"%Y%m%d")


CONSEC_GLOBAL_FILE="/home/markmur88/.backup_zip_consecutivo_general"
CONSEC_DAILY_FILE="/home/markmur88/.backup_zip_consecutivo_diario_$DATE_SHORT"

RESET='\033[0m'
AMARILLO='\033[1;33m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
AZUL='\033[1;34m'

log_info()  { echo -e "${AZUL}[INFO] $1${RESET}" | tee -a "$LOG_BACKUP"; }
log_ok()    { echo -e "${VERDE}[OK]   $1${RESET}" | tee -a "$LOG_BACKUP"; }
log_error() { echo -e "${ROJO}[ERR]  $1${RESET}" | tee -a "$LOG_BACKUP"; }

check_and_log() {
    if [ $? -eq 0 ]; then
        log_ok "$1"
    else
        log_error "$2"
        exit 1
    fi
}

cd "$BASE_DIR" || { echo -e "${ROJO}❌ ERROR: No se pudo acceder a BASE_DIR ($BASE_DIR)${RESET}"; exit 1; }

if [[ ! -f ".env" ]]; then
    log_error "No se encontró el archivo .env"
    exit 1
fi

source .env

check_and_log "Carpetas LOG y BACKUP verificadas/creadas" "No se pudo crear/verificar carpetas LOG/BACKUP"

log_info "📦 Preparando respaldo ZIP del proyecto..."

# if [ ! -d "$BASE_DIR" ]; then
#     log_error "Directorio del proyecto no encontrado: $BASE_DIR"
#     exit 1
# fi

# if [ ! -d "$BASE_DIR/schemas" ]; then
#     log_error "Directorio 'schemas/' no encontrado en el proyecto"
#     exit 1
# fi

# if [ ! -d "$BASE_DIR/logs" ]; then
#     log_error "Directorio 'logs/' no encontrado en el proyecto"
#     exit 1
# fi

if [ ! -f "$CONSEC_GLOBAL_FILE" ]; then echo "0" > "$CONSEC_GLOBAL_FILE"; fi
CONSEC_GLOBAL=$(<"$CONSEC_GLOBAL_FILE")
CONSEC_GLOBAL=$((CONSEC_GLOBAL + 1))
printf "%d" "$CONSEC_GLOBAL" > "$CONSEC_GLOBAL_FILE"
CONSEC_GLOBAL_FMT=$(printf "G%04d" "$CONSEC_GLOBAL")

if [ ! -f "$CONSEC_DAILY_FILE" ]; then echo "0" > "$CONSEC_DAILY_FILE"; fi
CONSEC_DAILY=$(<"$CONSEC_DAILY_FILE")
CONSEC_DAILY=$((CONSEC_DAILY + 1))
printf "%d" "$CONSEC_DAILY" > "$CONSEC_DAILY_FILE"
CONSEC_DAILY_FMT=$(printf "D%03d" "$CONSEC_DAILY")

ZIP_NAME="backup_completo_${DATE}_${CONSEC_GLOBAL_FMT}_${CONSEC_DAILY_FMT}.zip"
ZIP_FINAL="$BACKUP_DIR/zip/$ZIP_NAME"

log_info "🧩 Iniciando compresión del proyecto completo..."

cd "$PROJECT_BASE_DIR" || { log_error "No se pudo acceder al directorio base del proyecto"; exit 1; }

EXCLUDES=(
  "$(basename "$BASE_DIR")/__pycache__/*"
  "$(basename "$BASE_DIR")/migrations/*"
  "$(basename "$BASE_DIR")/*.sqlite3"
  "$(basename "$BASE_DIR")/*.pyc"
  "$(basename "$BASE_DIR")/*.conf"
  "$(basename "$BASE_DIR")/*.service"
  "$(basename "$BASE_DIR")/*.sock"
  "$(basename "$BASE_DIR")/*.zip"
  "$(basename "$BASE_DIR")/*.sql"
  "$(basename "$BASE_DIR")/.DS_Store"
  "$(basename "$BASE_DIR")/venv/*"
)

zip -r9 "$ZIP_FINAL" "$(basename "$BASE_DIR")" "${EXCLUDES[@]/#/-x}" >> "$LOG_BACKUP" 2>&1

check_and_log "Proyecto comprimido exitosamente en: $ZIP_FINAL" "Error al comprimir el proyecto"

log_ok "✅ Script finalizado correctamente. Log disponible en: $LOG_BACKUP"
