#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M).log"
mkdir -p "$(dirname $LOG_DEPLOY)"


echo -e "\033[7;30m🚀 Subiendo respaldo de datos de local...\033[0m" | tee -a $LOG_DEPLOY
python3 manage.py loaddata bdd_local.json
echo -e "\033[7;30m✅ ¡Subido JSON Local!\033[0m" | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
