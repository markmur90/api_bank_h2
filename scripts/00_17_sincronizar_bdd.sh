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


echo -e "\033[7;30mSubiendo las bases de datos a la web...\033[0m" | tee -a $LOG_DEPLOY
LOCAL_DB_NAME="mydatabase"
LOCAL_DB_USER="markmur88"
LOCAL_DB_HOST="localhost"

REMOTE_DB_URL="postgres://u22qfesn1ol61g:p633435fd268a16298ff6b2b83e47e7091ae5cb79d80ad13e03a6aff1262cc2ae@c7pvjrnjs0e7al.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/ddo6kmmjfftuav"

export PGPASSFILE="$HOME/.pgpass"
export PGUSER="$LOCAL_DB_USER"
export PGHOST="$LOCAL_DB_HOST"

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/Documentos/GitHub/backup/sql/"
BACKUP_FILE="${BACKUP_DIR}backup_local.sql"

if ! command -v pv > /dev/null 2>&1; then
    echo "⚠️ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv" | tee -a $LOG_DEPLOY
    exit 1
fi
echo -e "\033[7;30m🧹 Reseteando base de datos remota...\033[0m" | tee -a $LOG_DEPLOY
psql "$REMOTE_DB_URL" -q -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || { echo "❌ Error al resetear la DB remota. Abortando."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
# echo -e "\033[7;30m📦 Generando backup local...\033[0m" | tee -a $LOG_DEPLOY
# pg_dump --no-owner --no-acl -U "$LOCAL_DB_USER" -h "$LOCAL_DB_HOST" -d "$LOCAL_DB_NAME" > "$BACKUP_FILE" || { echo "❌ Error haciendo el backup local. Abortando."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo -e "\033[7;30m🌐 Importando backup en la base de datos remota...\033[0m" | tee -a $LOG_DEPLOY
pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" -q > /dev/null || { echo "❌ Error al importar el backup en la base de datos remota."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo -e "\033[7;30m✅ Sincronización completada con éxito: $BACKUP_FILE" | tee -a $LOG_DEPLOY
export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
