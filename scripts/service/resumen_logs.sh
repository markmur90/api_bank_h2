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
# 1. Carpeta absoluta donde está este script


# 2. Detectar proyecto raíz:
#    - Si script está en .../scripts, el root es su padre;
#    - Si está en root, el root es SCRIPT_DIR.
if [[ "$(basename "$SCRIPTS_DIR")" == "scripts" ]]; then
    BASE_DIR="$(dirname "$SCRIPTS_DIR")"
else
    BASE_DIR="$SCRIPTS_DIR"
fi

# 3. Carpeta de logs
LOG_DIR="$BASE_DIR/scripts/logs"

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
