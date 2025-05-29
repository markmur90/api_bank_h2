#!/usr/bin/env bash
set -euo pipefail

# 1. Detectar ubicación del script y proyecto raíz
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

# 2. Carpeta de logs
LOG_DIR="$PROJECT_ROOT/scripts/logs"

echo -e "📊 Resumen por carpeta de logs:"
echo -e "═══════════════════════════════════════════════════════════"

# 3. Obtener carpetas únicas con .log
mapfile -t DIRS < <(
    find "$LOG_DIR" -type f -name "*.log" -printf '%h\n' \
      | sort -u
)

# 4. Para cada carpeta, imprimir su encabezado y listar sus logs
for dir in "${DIRS[@]}"; do
    # Ruta relativa a logs
    rel="${dir#$LOG_DIR/}"
    echo -e "\n📂 Carpeta: ${rel:-.}"  
    echo "───────────────────────────────────────────────────────────"
    printf "%-30s | %-19s | %-30s\n" "Script" "Fecha" "Último estado"
    echo "------------------------------------------------------------------"
    
    # Recorrer solo los logs en esta carpeta
    find "$dir" -maxdepth 1 -type f -name "*.log" | sort | while read -r log; do
        script_name=$(basename "$log" .log)
        
        raw_fecha=$(grep -m1 "📅 Fecha de ejecución:" "$log" 2>/dev/null || true)
        if [[ -n $raw_fecha ]]; then
            fecha=$(echo "$raw_fecha" | cut -d':' -f2- | xargs)
        else
            fecha="N/A"
        fi
        
        estado=$(tail -n 1 "$log" | cut -c1-30)
        
        printf "%-30s | %-19s | %-30s\n" \
               "$script_name" "$fecha" "$estado"
    done
done
