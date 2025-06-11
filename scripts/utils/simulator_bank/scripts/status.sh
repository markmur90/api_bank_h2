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

# Activar entorno virtual
source "$VENV_PATH/bin/activate"

SUPERVISOR_CONF="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/config/supervisor_simulador.conf"


echo "▶️ Servicios arrancados:"
supervisorctl -c "$SUPERVISOR_CONF" status
