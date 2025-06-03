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


# echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m" | tee -a $LOG_DEPLOY
# python3 manage.py loaddata bdd_local.json


# echo -e "\033[7;30m🚀 Restaurando base de datos desde respaldo SQL...\033[0m" | tee -a "$LOG_DEPLOY"

# BACKUP_DIR_SQL="$HOME/backup/sql"
# export PGPASSWORD="Ptf8454Jd55"
# psql -U markmur88 -h 127.0.0.1 -p 5432 -d mydatabase \
#   < "$BACKUP_DIR_SQL/backup_local.sql" 2>>"$LOG_DEPLOY"
# unset PGPASSWORD

LOCAL_DB_NAME="mydatabase"
LOCAL_DB_USER="markmur88"
LOCAL_DB_HOST="localhost"

export PGPASSFILE="$HOME/.pgpass"
export PGUSER="$LOCAL_DB_USER"
export PGHOST="$LOCAL_DB_HOST"

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/backup/sql/"
BACKUP_FILE="${BACKUP_DIR}backup_local.sql"

if ! command -v pv > /dev/null 2>&1; then
    echo "⚠️ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv" | tee -a $LOG_DEPLOY
    exit 1
fi

DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"



# dropdb -U usuario mydatabase
# createdb -U usuario mydatabase


echo -e "\033[7;30m🌐 Importando backup del archivo...\033[0m" | tee -a $LOG_DEPLOY
# echo -e "\033[7;30m📦 Generando backup local...\033[0m" | tee -a $LOG_DEPLOY
# pg_dump --no-owner --no-acl -U "$LOCAL_DB_USER" -h "$LOCAL_DB_HOST" -d "$LOCAL_DB_NAME" > "$BACKUP_FILE" || { echo "❌ Error haciendo el backup local. Abortando."; exit 1; }
pv "$BACKUP_FILE" | psql "$DATABASE_URL" -q > /dev/null || { echo "❌ Error al importar el backup del archivo."; exit 1; }

echo -e "\033[7;32m✅ Restauración SQL completada.\033[0m" | tee -a "$LOG_DEPLOY"



echo -e "\033[7;30m✅ ¡Subido SQL Local!\033[0m" | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
