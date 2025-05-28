#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


# echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m" | tee -a $LOG_DEPLOY
# python3 manage.py loaddata bdd_local.json


# echo -e "\033[7;30m🚀 Restaurando base de datos desde respaldo SQL...\033[0m" | tee -a "$LOG_DEPLOY"

# BACKUP_DIR_SQL="$HOME/Documentos/GitHub/backup/sql"
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
BACKUP_DIR="$HOME/Documentos/GitHub/backup/sql/"
BACKUP_FILE="${BACKUP_DIR}backup_local.sql"

DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"

echo -e "\033[7;30m🌐 Importando backup en la base de datos remota...\033[0m" | tee -a $LOG_DEPLOY
pv "$BACKUP_FILE" | psql "$DATABASE_URL" -q > /dev/null || { echo "❌ Error al importar el backup en la base de datos remota."; exit 1; }

echo -e "\033[7;32m✅ Restauración SQL completada.\033[0m" | tee -a "$LOG_DEPLOY"



echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m" | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
