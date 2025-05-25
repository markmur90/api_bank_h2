#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="./logs"
echo -e "📊 Resumen de ejecución de scripts:"
echo -e "═════════════════════════════════════════════════════════════════"
printf "%-40s | %-19s | %-30s\n" "Script" "Fecha" "Último estado"
echo "--------------------------------------------------------------------------"

find "$LOG_DIR" -type f -name "*.log" | while read -r log; do
    script_name=$(basename "$log" | sed 's/_.log$//')
    fecha=$(grep -m1 "📅 Fecha de ejecución:" "$log" | cut -d':' -f2- | xargs)
    estado=$(tail -n 1 "$log" | cut -c1-30)
    printf "%-40s | %-19s | %-30s\n" "$script_name" "$fecha" "$estado"
done
