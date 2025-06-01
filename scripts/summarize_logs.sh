#!/usr/bin/env bash
set -euo pipefail

# Colores ANSI
colors=(
  "\e[31m"  # rojo
  "\e[32m"  # verde
  "\e[33m"  # amarillo
  "\e[34m"  # azul
  "\e[35m"  # magenta
  "\e[36m"  # cian
)
reset="\e[0m"

# 1. Detectar ubicación del script y proyecto raíz
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$(basename "$SCRIPT_DIR")" == "scripts" ]]; then
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
else
    PROJECT_ROOT="$SCRIPT_DIR"
fi

# 2. Carpeta de logs
LOG_DIR="$PROJECT_ROOT/scripts/logs"

# 2.a Validar que exista
if [[ ! -d "$LOG_DIR" ]]; then
    echo "⚠️  No existe el directorio de logs: $LOG_DIR"
    exit 1
fi

echo -e "📊 Resumen por carpeta de logs:"
echo -e "═══════════════════════════════════════════════════════════"

# 3. Obtener carpetas únicas con .log (portátil, sin abortar si no hay nada)
mapfile -t DIRS < <(
    find "$LOG_DIR" -type f -name "*.log" 2>/dev/null \
      | sed 's|/[^/]*$||' \
      | sort -u
)

# 3.a Avisar si no hay archivos
if [[ ${#DIRS[@]} -eq 0 ]]; then
    echo "ℹ️  No se encontraron archivos .log en $LOG_DIR"
    exit 0
fi

# Contador para alternar color
i=0
n_colors=${#colors[@]}

# 4. Para cada carpeta, imprimir su encabezado coloreado y listar sus logs
for dir in "${DIRS[@]}"; do
    color="${colors[$(( i % n_colors ))]}"
    ((i++))

    # Ruta relativa a logs
    rel="${dir#$LOG_DIR/}"
    printf "\n%b📂 Carpeta: %s%b\n" "$color" "${rel:-.}" "$reset"
    echo "───────────────────────────────────────────────────────────"
    printf "%-30s | %-19s | %-30s\n" "Script" "Fecha" "Último estado"
    echo "------------------------------------------------------------------"
    
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
