#!/usr/bin/env bash
set -euo pipefail

echo -e "\033[7;30mSubiendo las bases de datos a la web...\033[0m"
LOCAL_DB_NAME="mydatabase"
LOCAL_DB_USER="markmur88"
LOCAL_DB_HOST="localhost"
REMOTE_DB_URL="postgres://u5n97bps7si3fm:pb87bf621ec80bf56093481d256ae6678f268dc7170379e3f74538c315bd549e0@c7lolh640htr57.cluster-czz5s0kz4scl.eu-west-1.rds.amazonaws.com:5432/dd3ico8cqsq6ra"

export PGPASSFILE="$HOME/.pgpass"
export PGUSER="$LOCAL_DB_USER"
export PGHOST="$LOCAL_DB_HOST"

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/Documentos/GitHub/backup/sql/"
BACKUP_FILE="${BACKUP_DIR}backup_${DATE}.sql"

if ! command -v pv > /dev/null 2>&1; then
    echo "⚠️ La herramienta 'pv' no está instalada. Instálala con: sudo apt install pv"
    exit 1
fi
echo -e "\033[7;30m🧹 Reseteando base de datos remota...\033[0m"
psql "$REMOTE_DB_URL" -q -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || { echo "❌ Error al resetear la DB remota. Abortando."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
echo -e "\033[7;30m📦 Generando backup local...\033[0m"
pg_dump --no-owner --no-acl -U "$LOCAL_DB_USER" -h "$LOCAL_DB_HOST" -d "$LOCAL_DB_NAME" > "$BACKUP_FILE" || { echo "❌ Error haciendo el backup local. Abortando."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
echo -e "\033[7;30m🌐 Importando backup en la base de datos remota...\033[0m"
pv "$BACKUP_FILE" | psql "$REMOTE_DB_URL" -q > /dev/null || { echo "❌ Error al importar el backup en la base de datos remota."; exit 1; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
echo -e "\033[7;30m✅ Sincronización completada con éxito: $BACKUP_FILE"
export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""