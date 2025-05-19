#!/bin/bash

PROJECT_DIR="/home/markmur88/Documentos/GitHub/api_bank_h2"
PROJECT_BASE_DIR="/home/markmur88/Documentos/GitHub"
BACKUP_DIR="$PROJECT_BASE_DIR/backup"

DATE=$(date +"%Y%m%d_%H%M%S")
DATE_SHORT=$(date +"%Y%m%d")
LOG_FILE_SCRIPT="$PROJECT_DIR/logs/registro_script_$DATE.log"

CONSEC_GLOBAL_FILE="$HOME/.backup_zip_consecutivo_general"
CONSEC_DAILY_FILE="$HOME/.backup_zip_consecutivo_diario_$DATE_SHORT"

RESET='\033[0m'
AMARILLO='\033[1;33m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
AZUL='\033[1;34m'

check_and_log() {
    if [ $? -eq 0 ]; then
        echo -e "${VERDE}$1${RESET}"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] OK: $1" >> "$LOG_FILE_SCRIPT"
    else
        echo -e "${ROJO}$2${RESET}"
        echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR: $2" >> "$LOG_FILE_SCRIPT"
        exit 1
    fi
}

# Inicializar o incrementar consecutivo general
if [ ! -f "$CONSEC_GLOBAL_FILE" ]; then echo "0" > "$CONSEC_GLOBAL_FILE"; fi
CONSEC_GLOBAL=$(cat "$CONSEC_GLOBAL_FILE")
CONSEC_GLOBAL=$((CONSEC_GLOBAL + 1))
printf "%d" "$CONSEC_GLOBAL" > "$CONSEC_GLOBAL_FILE"
CONSEC_GLOBAL_FMT=$(printf "G%04d" "$CONSEC_GLOBAL")

# Inicializar o incrementar consecutivo por día
if [ ! -f "$CONSEC_DAILY_FILE" ]; then echo "0" > "$CONSEC_DAILY_FILE"; fi
CONSEC_DAILY=$(cat "$CONSEC_DAILY_FILE")
CONSEC_DAILY=$((CONSEC_DAILY + 1))
printf "%d" "$CONSEC_DAILY" > "$CONSEC_DAILY_FILE"
CONSEC_DAILY_FMT=$(printf "D%03d" "$CONSEC_DAILY")

ZIP_NAME="backup_completo_${DATE}_${CONSEC_GLOBAL_FMT}_${CONSEC_DAILY_FMT}.zip"
ZIP_FINAL="$BACKUP_DIR/$ZIP_NAME"

echo -e "${AMARILLO}📦 INICIANDO COMPRESIÓN DEL PROYECTO COMPLETO...${RESET}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${ROJO}❌ ERROR: Directorio del proyecto no encontrado: $PROJECT_DIR${RESET}"
    exit 1
fi

cd "$PROJECT_BASE_DIR" || {
    echo -e "${ROJO}❌ ERROR: No se pudo acceder al directorio base del proyecto${RESET}"
    exit 1
}

mkdir -p "$BACKUP_DIR"
check_and_log "📁 Carpeta de backup verificada o creada: $BACKUP_DIR" "❌ No se pudo crear/verificar la carpeta de backup"

if [ ! -d "$PROJECT_DIR/schemas" ]; then
    echo -e "${ROJO}❌ ERROR: Directorio 'schemas/' no encontrado en el proyecto${RESET}"
    exit 1
fi

if [ ! -d "$PROJECT_DIR/logs" ]; then
    echo -e "${ROJO}❌ ERROR: Directorio 'logs/' no encontrado en el proyecto${RESET}"
    exit 1
fi

echo -e "${AZUL}🧩 Comprimiendo todos los archivos de $(basename "$PROJECT_DIR")...${RESET}"
zip -r9 "$ZIP_FINAL" "$(basename "$PROJECT_DIR")" >> "$LOG_FILE_SCRIPT" 2>&1
check_and_log "📦 Proyecto comprimido exitosamente en: $ZIP_FINAL" "❌ Error al comprimir el proyecto"

echo -e "${VERDE}✅ Script finalizado correctamente. Log: $LOG_FILE_SCRIPT${RESET}"
