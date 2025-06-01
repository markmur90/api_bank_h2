#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
# 1. Carpeta absoluta donde está este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 2. Detectar proyecto raíz:
#    - Si script está en .../scripts, el root es su padre;
#    - Si está en root, el root es SCRIPT_DIR.
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

# 3. Carpeta de logs
LOG_DIR="$PROJECT_ROOT/scripts/logs"

# 4. Imprimir resumen
echo -e "📊 Resumen de ejecución de scripts:"
echo -e "═══════════════════════════════════════════════"
printf "%-40s | %-19s | %-30s\n" "Script" "Fecha" "Último estado"
echo "--------------------------------------------------------------------------"

find "$LOG_DIR" -type f -name "*.log" | sort | while read -r log; do
    script_name=$(basename "$log" .log)
    fecha=$(grep -m1 "📅 Fecha de ejecución:" "$log" \
            | cut -d':' -f2- \
            | xargs)
    estado=$(tail -n 1 "$log" | cut -c1-30)
    printf "%-40s | %-19s | %-30s\n" \
           "$script_name" "$fecha" "$estado"
done
