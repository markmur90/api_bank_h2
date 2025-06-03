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
LOG_BACKUP="$SCRIPT_DIR/logs/backup/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_BACKUP)"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PROJECT_ROOT="$HOME/api_bank_h2"
PROJECT_BASE_DIR="$HOME"
BACKUP_DIR="$PROJECT_BASE_DIR/backup/zip"

DATE=$(date +"%Y%m%d_%H%M%S")
DATE_SHORT=$(date +"%Y%m%d")


CONSEC_GLOBAL_FILE="$HOME/.backup_zip_consecutivo_general"
CONSEC_DAILY_FILE="$HOME/.backup_zip_consecutivo_diario_$DATE_SHORT"

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

# if [ ! -d "$PROJECT_ROOT" ]; then
#     log_error "Directorio del proyecto no encontrado: $PROJECT_ROOT"
#     exit 1
# fi

# if [ ! -d "$PROJECT_ROOT/schemas" ]; then
#     log_error "Directorio 'schemas/' no encontrado en el proyecto"
#     exit 1
# fi

# if [ ! -d "$PROJECT_ROOT/logs" ]; then
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
  "$(basename "$PROJECT_ROOT")/__pycache__/*"
  "$(basename "$PROJECT_ROOT")/migrations/*"
  "$(basename "$PROJECT_ROOT")/*.sqlite3"
  "$(basename "$PROJECT_ROOT")/*.pyc"
  "$(basename "$PROJECT_ROOT")/*.conf"
  "$(basename "$PROJECT_ROOT")/*.service"
  "$(basename "$PROJECT_ROOT")/*.sock"
  "$(basename "$PROJECT_ROOT")/*.zip"
  "$(basename "$PROJECT_ROOT")/*.sql"
  "$(basename "$PROJECT_ROOT")/.DS_Store"
)

zip -r9 "$ZIP_FINAL" "$(basename "$PROJECT_ROOT")" "${EXCLUDES[@]/#/-x}" >> "$LOG_BACKUP" 2>&1

check_and_log "Proyecto comprimido exitosamente en: $ZIP_FINAL" "Error al comprimir el proyecto"

log_ok "✅ Script finalizado correctamente. Log disponible en: $LOG_BACKUP"
