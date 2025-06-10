#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail



LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"

BASE_DIR="$AP_H2_DIR"
NJALLA_ROOT="/home/markmur88/coretransapi"
HEROKU_ROOT="$AP_HK_DIR"


EXCLUDES=(
    "--exclude=*.zip"
    "--exclude=*.db"
    "--exclude=*.sqlite3"
    "--exclude=.vscode/"
    "--exclude=base0.py"
    "--exclude=base2.py"
    "--exclude=*old.py"
    # "--exclude=* copy*"
    # "--exclude=/scripts/"
    # "--exclude=/tmp/"
    # "--exclude=/temp/"
    # "--exclude=/z_njalla/"
    # "--exclude=/servers/"
    # "--exclude=/logs/"
    # "--exclude=/.vscode/"
    # "--exclude=/.github/"
    # "--exclude=/.devcontainer/"
    # "--exclude=/.codesandbox/"
    # "--exclude=01_full0.sh"
    # "--exclude=chatgpt.md"
    # "--exclude=datos_sensibles.txt"
    # "--exclude=chmod_log.txt"
    # "--exclude=pendientes.txt"
    # "--exclude=Problema.md"
    # "--exclude=prompts.txt"
    # "--exclude=navGeneral/"
    # "--exclude=navGeneral2.html"
    # "--exclude=navGeneralFuncional.html"
    # "--exclude=templates/form/"
    # "--exclude=templates/api/accounts/"
    # "--exclude=templates/api/collection/"
    # "--exclude=templates/api/GPT/"
    # "--exclude=templates/api/sandbox/"
    # "--exclude=templates/api/SCT/"
    # "--exclude=templates/api/sepa_payment/"
    # "--exclude=templates/api/transactions/"
    # "--exclude=schemas/certs/"
    # "--exclude=schemas/keys/"
    # "--exclude=/certs/"
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
    sudo rsync -av "${EXCLUDES[@]}" "$BASE_DIR/" "$destino/"
    echo -e "\033[7;30m📂 Cambios enviados a $destino.\033[0m"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
    cd "$destino"
    actualizar_django_env "$destino"
    cd "$BASE_DIR"
    echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
    echo ""
done