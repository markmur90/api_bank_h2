#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M).log"
mkdir -p "$(dirname $LOG_DEPLOY)"


echo -e "\033[7;30m🚀 Verificando logs transferencias...\033[0m" | tee -a $LOG_DEPLOY
python manage.py verificar_transferencias --fix -c -j
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
