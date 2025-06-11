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

set -e

bash /home/markmur88/api_bank_h2/scripts/utils/simulator_bank/scripts/ports_stop.sh


SUPERVISOR_CONF="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/config/supervisor_simulador.conf"

manage_supervised() {
    local svc="$1"
    local status
    status=$(supervisorctl -c "$SUPERVISOR_CONF" status "$svc" | awk '{print $2}')
    if [[ "$status" == "RUNNING" ]]; then
        echo "🔄 $svc ya está activo. Reiniciando..."
        supervisorctl -c "$SUPERVISOR_CONF" restart "$svc"
    else
        echo "▶️ $svc no está activo. Iniciando..."
        supervisorctl -c "$SUPERVISOR_CONF" start "$svc"
    fi
}


echo "📦 Creando entorno virtual y preparando entorno de trabajo..."
source $VENV_PATH/bin/activate

echo "⬆️  Actualizando pip e instalando dependencias..."
pip install --upgrade pip
pip install -r /home/markmur88/api_bank_h2/scripts/utils/simulator_bank/simulador_banco/requirements.txt

echo "✅ Dependencias instaladas correctamente"
echo "▶️ Iniciando servicio de supervisión (supervisord)..."

supervisord -c /home/markmur88/api_bank_h2/scripts/utils/simulator_bank/config/supervisor_simulador.conf

supervisorctl -c "$SUPERVISOR_CONF" status
