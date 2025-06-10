#!/usr/bin/env bash
# Hace todos los scripts *.sh, *.py, etc. ejecutables

set -euo pipefail

LOG_FILE="chmod_log.txt"
touch "$LOG_FILE"

echo "📁 Iniciando chmod +x recursivo desde: $(pwd)"
echo "📝 Log guardado en: $LOG_FILE"
echo ""

find . -type f \( -name "*.sh" -o -name "*.py" -o -name "*.pl" -o -name "*.rb" -o -name "*.cgi" \) ! -perm -111 | while read -r file; do
    chmod +x "$file"
    echo "✅ chmod +x -> $file" | tee -a "$LOG_FILE"
done

echo ""
echo "✅ Archivos ejecutables listos"
