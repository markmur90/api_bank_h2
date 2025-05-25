#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./logs/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_BACKUP="$SCRIPT_DIR/logs/backup/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_BACKUP)"


echo -e "\033[7;30mLimpiando respaldos antiguos...\033[0m" | tee -a $LOG_BACKUP
echo "" | tee -a $LOG_BACKUP

limpiar_respaldo_por_hora() {
    local DIR="$1"
    cd "$DIR" || exit 1

    mapfile -t files < <(ls -1tr *.zip *.sql 2>/dev/null)

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

BACKUP_DIR_ZIP=$HOME/Documentos/GitHub/backup/zip
BACKUP_DIR_SQL=$HOME/Documentos/GitHub/backup/sql

limpiar_respaldo_por_hora "$BACKUP_DIR_ZIP"
limpiar_respaldo_por_hora "$BACKUP_DIR_SQL"