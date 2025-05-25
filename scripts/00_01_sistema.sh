#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M).log"
mkdir -p "$(dirname $LOG_SISTEMA)"


sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m" | tee -a $LOG_SISTEMA
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
echo "" | tee -a $LOG_SISTEMA
