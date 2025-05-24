#!/usr/bin/env bash
set -euo pipefail

ENTORNOS=("local" "heroku" "production" "📘 Ver ayuda de despliegue")
echo -e "\033[1;36m🌍 Selecciona entorno(s) o acción:\033[0m"
SELECCION=$(printf "%s\n" "${ENTORNOS[@]}" | fzf --multi --header="⬇ Usa espacio para seleccionar múltiples")

[[ -z "$SELECCION" ]] && { echo -e "\033[1;31m❌ Cancelado\033[0m"; exit 1; }

if echo "$SELECCION" | grep -q "📘"; then
    echo -e "\n\033[1;36mEJEMPLOS COMBINADOS DISPONIBLES:\033[0m"
    echo -e "  \033[1;33md_help\033[0m           ➤ Ver la ayuda completa del script"
    echo -e "  \033[1;33md_all\033[0m            ➤ Ejecutar absolutamente todo sin confirmaciones"
    echo -e "  \033[1;33md_step\033[0m           ➤ Ejecutar paso a paso, confirmando cada bloque"
    echo -e "  \033[1;33md_debug\033[0m          ➤ Mostrar todas las variables antes de ejecutar"

    echo -e "\n  \033[1;33md_local\033[0m          ➤ Despliegue local completo sin Heroku ni VPS"
    echo -e "  \033[1;33md_heroku\033[0m         ➤ Sincronizar archivos y subir solo a Heroku"
    echo -e "  \033[1;33md_production\033[0m     ➤ Despliegue para VPS Njalla (sin Heroku)"

    echo -e "\n  \033[1;33md_reset_full\033[0m     ➤ Reinstalación completa del entorno"
    echo -e "  \033[1;33md_sync\033[0m           ➤ Solo sincronizar archivos locales sin otras acciones"

    echo -e "\n  \033[1;33md_push_heroku\033[0m    ➤ Ejecutar solo push a GitHub + Heroku"
    echo -e "  \033[1;33md_njalla\033[0m          ➤ Subida directa al VPS Njalla (coretransapi.com)"

    echo -e "\n  \033[1;33mdeploy_menu\033[0m      ➤ Menú interactivo con FZF para seleccionar despliegue"
    echo -e "\n\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m\n"
    exit 0
fi

for ENTORNO in $SELECCION; do
    echo -e "\n=============================="
    echo -e "🌍 Ejecutando entorno: $ENTORNO"
    echo -e "=============================="
    ./01_full.sh --env=$ENTORNO -a || echo "❌ Falló: $ENTORNO"
done
