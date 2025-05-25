#!/usr/bin/env bash
set -euo pipefail

PUERTOS_OCUPADOS=0

for PUERTO in 2222 8000 5000 8001 35729; do
    if lsof -i tcp:"$PUERTO" &>/dev/null; then
        PUERTOS_OCUPADOS=$((PUERTOS_OCUPADOS + 1))
        if confirmar "Cerrar procesos en puerto $PUERTO"; then
            sudo fuser -k "${PUERTO}"/tcp || true
            echo -e "\033[7;30m✅ Puerto $PUERTO liberado.\033[0m"
            echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
            echo ""
        fi
    fi
done

if [ "$PUERTOS_OCUPADOS" -eq 0 ]; then
    echo -e "\033[7;31m🚫 No se encontraron procesos en los puertos definidos.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
fi
