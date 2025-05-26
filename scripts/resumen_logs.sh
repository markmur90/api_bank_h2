#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"
echo -e "📊 Resumen de ejecución de scripts:"
echo -e "═════════════════════════════════════════════════════════════════"
printf "%-40s | %-19s | %-30s\n" "Script" "Fecha" "Último estado"
echo "--------------------------------------------------------------------------"

find "$(dirname "$LOG_FILE")" -type f -name "*.log" | while read -r log; do
    script_name=$(basename "$log" | sed 's/_.log$//')
    fecha=$(grep -m1 "📅 Fecha de ejecución:" "$log" | cut -d':' -f2- | xargs)
    estado=$(tail -n 1 "$log" | cut -c1-30)
    printf "%-40s | %-19s | %-30s\n" "$script_name" "$fecha" "$estado"
done
