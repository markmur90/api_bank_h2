#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


echo -e "\033[7;30m🚀 Creando respaldo de datos de local...\033[0m" | tee -a $LOG_DEPLOY
export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
python3 manage.py dumpdata --indent 2 > bdd_local.json
echo -e "\033[7;30m✅ ¡Respaldo JSON Local creado!\033[0m" | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
