#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"


PIDS=$(docker ps -q)
if [ -n "$PIDS" ]; then
    docker stop $PIDS
    echo -e "\033[7;30m🐳 Contenedores detenidos.\033[0m" | tee -a $LOG_SISTEMA
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
    echo "" | tee -a $LOG_SISTEMA
else
    echo -e "\033[7;30m🐳 No hay contenedores.\033[0m" | tee -a $LOG_SISTEMA
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_SISTEMA
    echo "" | tee -a $LOG_SISTEMA
fi