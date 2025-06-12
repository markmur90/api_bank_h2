#!/bin/bash
set -e
VENV_PATH="/home/markmur88/envAPP"

echo "🔁 Parando todas las instancias de supervisord..."

# Matar todos los supervisord activos
pkill -f "supervisord -c .*supervisor_simulador.conf"

# bash /home/markmur88/Simulador/scripts/ports_stop.sh


# Limpiar sockets y pids viejos
rm -f /home/markmur88/Simulador/logs/supervisord.sock
rm -f /home/markmur88/Simulador/logs/supervisord.pid

echo "✅ Limpieza hecha."

# Activar entorno y relanzar
source $VENV_PATH/bin/activate

echo "🚀 Lanzando supervisord limpio..."
supervisord -c /home/markmur88/Simulador/config/supervisor_simulador.conf

sleep 5
supervisorctl -c /home/markmur88/Simulador/config/supervisor_simulador.conf restart gunicorn
sleep 5

supervisorctl -c /home/markmur88/Simulador/config/supervisor_simulador.conf status

