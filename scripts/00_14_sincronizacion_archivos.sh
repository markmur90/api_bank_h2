#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"

PROJECT_ROOT="$HOME/api_bank_h2"
NJALLA_ROOT="$HOME/coretransapi"
HEROKU_ROOT="$HOME/api_bank_heroku"


EXCLUDES=(
    "--exclude=*.zip"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=.vscode/"
    "--exclude=base0.py"
    "--exclude=*old.py"
    "--exclude=* copy*"
)

actualizar_django_env() {
    local destino="$1"
    echo "🧾 Ajustando DJANGO_ENV en base1.py en $destino"
    python3 <<EOF | tee -a "$LOG_DEPLOY"
import os
settings_path = os.path.join("$destino", "config", "settings", "__init__.py")
if os.path.exists(settings_path):
    with open(settings_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    updated = False
    new_lines = []
    for line in lines:
        if "DJANGO_ENV = os.getenv(" in line and "'local'" in line:
            new_lines.append(line.replace("'local'", "'production'"))
            updated = True
        else:
            new_lines.append(line)
    if updated:
        with open(settings_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print("✅ DJANGO_ENV actualizado a "'local'" en __init__.py.")
    else:
        print("⚠️ No se encontró DJANGO_ENV='local' para actualizar.")
else:
    print("⚠️ No se encontró __init__.py en el destino.")
EOF
}

# for destino in "$HEROKU_ROOT" "$NJALLA_ROOT"; do
for destino in "$HEROKU_ROOT" ; do
    echo -e "\033[7;30m🔄 Sincronizando archivos al destino: $destino\033[0m"
    sudo rsync -av "${EXCLUDES[@]}" "$PROJECT_ROOT/" "$destino/"
    echo -e "\033[7;30m📂 Cambios enviados a $destino.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    cd "$destino"
    actualizar_django_env "$destino"
    cd "$PROJECT_ROOT"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
done