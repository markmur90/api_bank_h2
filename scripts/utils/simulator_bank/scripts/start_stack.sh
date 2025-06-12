#!/bin/bash
set -e

BASE_DIR="/home/markmur88/Simulador"
TOR_DIR="$BASE_DIR/tor_data/hidden_service"
SUPERVISORD_CONF="$BASE_DIR/config/supervisor_simulador.conf"
TORRC="$BASE_DIR/config/torrc_simulador"

echo "🧹 Limpiando procesos previos..."

# Matar procesos previos
pkill -f "supervisord.*$SUPERVISORD_CONF" 2>/dev/null || true
pkill -f "gunicorn.*simulador_banco.wsgi" 2>/dev/null || true
pkill -f "tor.*$TORRC" 2>/dev/null || true

# Matar tor por config
pkill -f "tor.*$TORRC" 2>/dev/null || true

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

cd "$BASE_DIR" || { echo "❌ No se pudo acceder a $BASE_DIR"; exit 1; }

echo "🔄 Iniciando supervisord..."
supervisord -c "$SUPERVISORD_CONF"
sleep 3

echo "🧅 Iniciando Tor..."
tor -f "$TORRC" &
TOR_PID=$!

sleep 3
echo ""

echo -n "⌛ Esperando a que Tor genere el .onion... "
for i in {1..10}; do
    if [ -f "$TOR_DIR/hostname" ]; then
        echo "✅"
        break
    fi
    sleep 1
done

sleep 3
echo ""

if [ ! -f "$TOR_DIR/hostname" ]; then
    echo "❌ No se generó el .onion en tiempo esperado."
    exit 1
fi

sleep 3
echo ""

echo "🧅 Servicio oculto disponible en:"
cat "$TOR_DIR/hostname"

sleep 3
echo ""

echo "📡 Stack activo. Tor PID: $TOR_PID"

sleep 3
echo ""

echo "⏸️  Pausando 5 segundos para visualizar estado..."

sleep 5

echo ""

SUPERVISOR_CONF="/home/markmur88/Simulador/config/supervisor_simulador.conf"

echo "▶️ Servicios arrancados:"
supervisorctl -c "$SUPERVISOR_CONF" status
echo ""
