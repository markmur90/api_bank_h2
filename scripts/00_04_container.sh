#!/usr/bin/env bash
set -euo pipefail

PIDS=$(docker ps -q)
if [ -n "$PIDS" ]; then
    docker stop $PIDS
    echo -e "\033[7;30m🐳 Contenedores detenidos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
else
    echo -e "\033[7;30m🐳 No hay contenedores.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi