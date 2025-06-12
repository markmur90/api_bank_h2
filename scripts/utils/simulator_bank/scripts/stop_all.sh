#!/bin/bash
set -e

SUPERVISOR_CONF="/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/config/supervisor_simulador.conf"

echo "⏹️ Deteniendo todos los procesos supervisados..."
supervisorctl -c "$SUPERVISOR_CONF" shutdown

echo ""
sleep 3


echo ""
sleep 3

echo "🧹 Limpiando procesos previos..."

# Matar procesos previos
pkill -f "supervisord.*$SUPERVISORD_CONF" 2>/dev/null || true
pkill -f "gunicorn.*simulador_banco.wsgi" 2>/dev/null || true
pkill -f "tor.*$TORRC" 2>/dev/null || true

# Matar tor por config
pkill -f "tor.*$TORRC" 2>/dev/null || true

echo ""
sleep 3

# Extra: matar lo que escuche en 9053 o 9054
for port in 9053 9054; do
    pid=$(lsof -ti tcp:$port 2>/dev/null || true)
    if [[ $pid ]]; then
        echo "⚠️  Cerrando proceso en puerto $port (PID $pid)"
        sudo kill -9 $pid
    fi
done
sleep 3
echo ""

# Matar cualquier proceso Tor sin importar cómo fue lanzado
echo "🧨 Terminando procesos Tor..."
sudo pgrep tor | while read -r pid; do
    echo "⚠️  Matando Tor PID $pid"
    sudo kill -9 "$pid"
done
sleep 3
echo ""