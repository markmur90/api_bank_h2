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

COLOR_OK='\033[1;32m'
COLOR_WARN='\033[1;33m'
COLOR_ERR='\033[1;31m'
COLOR_INFO='\033[1;34m'
COLOR_RESET='\033[0m'

echo -e "${COLOR_INFO}🔄 Reiniciando servicios del sistema...${COLOR_RESET}"
echo ""

SERVICIOS=("nginx" "supervisor" "tor")

# Verificación opcional de gunicorn si corre con supervisor
echo -e "${COLOR_INFO}🔍 Verificando presencia de gunicorn...${COLOR_RESET}"
if pgrep -f gunicorn >/dev/null; then
    echo -e "${COLOR_OK}✅ gunicorn está corriendo como proceso (probablemente supervisado).${COLOR_RESET}"
else
    echo -e "${COLOR_WARN}⚠ gunicorn no se detecta como proceso activo.${COLOR_RESET}"
fi
echo -e "${COLOR_INFO}------------------------------------------------------------${COLOR_RESET}"
echo ""

for srv in "${SERVICIOS[@]}"; do
    if systemctl list-units --type=service | grep -q "${srv}.service"; then
        echo -e "${COLOR_OK}✅ Servicio ${srv}.service encontrado.${COLOR_RESET}"

        if [[ "$srv" == "nginx" ]]; then
            echo -e "${COLOR_INFO}🔍 Validando configuración de nginx antes de reiniciar...${COLOR_RESET}"
            if ! sudo nginx -t; then
                echo -e "${COLOR_ERR}❌ Error en configuración de nginx. No se reiniciará.${COLOR_RESET}"
                continue
            fi
        fi

        if systemctl is-active --quiet "$srv"; then
            echo -e "${COLOR_INFO}🔁 Reiniciando $srv...${COLOR_RESET}"
            sudo systemctl restart "$srv"
            echo -e "${COLOR_OK}✅ $srv reiniciado correctamente.${COLOR_RESET}"
        else
            echo -e "${COLOR_WARN}⚠️  $srv no estaba activo. Iniciando...${COLOR_RESET}"
            if sudo systemctl start "$srv"; then
                echo -e "${COLOR_OK}✅ $srv iniciado correctamente.${COLOR_RESET}"
            else
                echo -e "${COLOR_ERR}❌ No se pudo iniciar $srv. Revisa 'systemctl status $srv'${COLOR_RESET}"
            fi
        fi
    else
        echo -e "${COLOR_ERR}❌ Servicio $srv no está disponible en este sistema.${COLOR_RESET}"
    fi
    echo -e "${COLOR_INFO}------------------------------------------------------------${COLOR_RESET}"
    echo ""
done

echo -e "${COLOR_OK}✅ Todos los servicios procesados.${COLOR_RESET}"
