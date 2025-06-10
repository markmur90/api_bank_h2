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


LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


# echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m" | tee -a $LOG_DEPLOY
# python3 manage.py loaddata bdd_local.json


# echo -e "\033[7;30m🚀 Restaurando base de datos desde respaldo SQL...\033[0m" | tee -a "$LOG_DEPLOY"

# BACKUP_DIR_SQL="/home/markmur88/backup/sql"
# export PGPASSWORD="Ptf8454Jd55"
# psql -U markmur88 -h 127.0.0.1 -p 5432 -d mydatabase \
#   < "$BACKUP_DIR_SQL/backup_local.sql" 2>>"$LOG_DEPLOY"
# unset PGPASSWORD

LOCAL_DB_NAME="mydatabase"
LOCAL_DB_USER="markmur88"
LOCAL_DB_HOST="localhost"

export PGPASSFILE="/home/markmur88/.pgpass"
export PGUSER="$LOCAL_DB_USER"
export PGHOST="$LOCAL_DB_HOST"

DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/home/markmur88/backup/sql/"
BACKUP_FILE="${BACKUP_DIR}backup_local.sql"

# 📦 Verificar e instalar 'pv' si falta
if ! command -v pv &>/dev/null; then
    OS="$(uname -s)"
    echo "⚠️ La herramienta 'pv' no está instalada. Instalando..." | tee -a "$LOG_DEPLOY"
    if [[ "$OS" == "Linux" ]]; then
        sudo apt update && sudo apt install -y pv
    elif [[ "$OS" == "Darwin" ]]; then
        brew update && brew install pv
    else
        echo "❌ OS no compatible para instalar 'pv'" | tee -a "$LOG_DEPLOY"
        exit 1
    fi
    echo "♻️ 'pv' instalada. Reiniciando script..." | tee -a "$LOG_DEPLOY"
    exec "$0" "$@"
fi

DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"



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
