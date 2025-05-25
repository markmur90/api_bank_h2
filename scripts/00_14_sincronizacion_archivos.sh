#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./logs/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
NJALLA_ROOT="$HOME/Documentos/GitHub/coretransapi"


EXCLUDES=(
    "--exclude=*.zip"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    # "--exclude=bin/"
    # "--exclude=scripts/"
    # "--exclude=scripts_njalla/"
    # "--exclude=servers/"
    # "--exclude=tmp/"
    # "--exclude=temp/"
    "--exclude=.env.heroku"
    # "--exclude=01_full.sh"
    # "--exclude=bdd_local.json"
    "--exclude=config_master.py"
    "--exclude=gunicorn.log"
    "--exclude=base0.py"
    "--exclude=local_old.py"
    "--exclude=production_old.py"
    "--exclude=honey*"
    "--exclude=livereload.log"
    "--exclude=master.sh"
    "--exclude=multi_master.sh"
    "--exclude=nginx.conf"
    "--exclude=post_install_coretransapi.sh"
    "--exclude=setup_coretransact.sh"
    "--exclude=sync.sh"
    # "--exclude=config/"


)

actualizar_django_env() {
    local destino="$1"
    echo "🧾 Ajustando DJANGO_ENV en __init__.py en $destino"
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
        print("✅ DJANGO_ENV actualizado a "'production'" en __init__.py.")
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