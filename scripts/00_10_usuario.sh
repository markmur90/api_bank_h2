#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M).log"
mkdir -p "$(dirname $LOG_SISTEMA)"


echo -e "\033[7;30m🚀 Creando usuario...\033[0m" | tee -a $LOG_SISTEMA
python3 manage.py createsuperuser
echo -e "\033[7;30m✅ ¡Usuario creado!\033[0m" | tee -a $LOG_SISTEMA
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
echo "" | tee -a $LOG_SISTEMA
