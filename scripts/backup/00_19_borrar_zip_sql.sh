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


echo -e "\033[7;30mLimpiando respaldos antiguos...\033[0m" | tee -a $LOG_BACKUP
echo "" | tee -a $LOG_BACKUP

limpiar_respaldo_por_hora() {
    local DIR="$1"
    cd "$DIR" || exit 1

    mapfile -t files < <(ls -1tr *.zip 2>/dev/null)

    declare -A keep_per_hour
    for f in "${files[@]}"; do
        name="${f%.*}"
        [[ "$name" =~ ([0-9]{8})_([0-9]{2}) ]] || continue
        clave="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}"
        keep_per_hour["$clave"]="$f"
    done

    declare -A keep
    for f in "${keep_per_hour[@]}"; do
        keep["$f"]=1
    done

    for f in "${files[@]}"; do
        if [[ -z "${keep[$f]:-}" ]]; then 
            rm -f "$f" && echo -e "\033[7;30m🗑️ Eliminado $f.\033[0m"
            echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_BACKUP
            echo "" | tee -a $LOG_BACKUP
        fi
    done

    cd - >/dev/null
}

BACKUP_DIR_ZIP=/home/markmur88/backup/zip
BACKUP_DIR_SQL=/home/markmur88/backup/sql

limpiar_respaldo_por_hora "$BACKUP_DIR_ZIP"
limpiar_respaldo_por_hora "$BACKUP_DIR_SQL"