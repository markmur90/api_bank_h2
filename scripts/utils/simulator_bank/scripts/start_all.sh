#!/bin/bash
set -e

SOCK_FILE="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/logs/supervisord.sock"
PID_FILE="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/logs/supervisord.pid"
LOG_DIR="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/logs"
VENV_PATH="/home/markmur88/envAPP"

# Variables de entorno
APP_DIR="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank"
CONF_PATH="$APP_DIR/config/gunicorn.conf.py"
DJANGO_WSGI="simulador_banco.wsgi:application"

# bash /home/markmur88/api_bank_h2/scripts/utils/simulator_bank/scripts/ports_stop.sh

# Activar entorno virtual
source "$VENV_PATH/bin/activate"

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

supervisorctl -c "$SUPERVISOR_CONF" start all

# Ruta al fichero de configuración de supervisord

echo "📋 Estado de servicios supervisados:"
supervisorctl -c "$SUPERVISOR_CONF" status
