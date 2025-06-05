#!/bin/bash

echo "🛑 Deteniendo servicios y procesos de Ghost Recon..."

PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
PROJECT_NAME="bank_ghost"
SOCK_FILE="$PROJECT_DIR/ghost.sock"

# 1. Detener Gunicorn vía supervisor (si está configurado)
echo "📦 Deteniendo Gunicorn (Supervisor)..."
if sudo supervisorctl status $PROJECT_NAME &>/dev/null; then
    sudo supervisorctl stop $PROJECT_NAME
fi

# 2. Detener procesos Gunicorn residuales antes de borrar socket
echo "🔪 Matando procesos gunicorn residuales..."
pkill -f gunicorn 2>/dev/null || echo "⚠️  No hay procesos gunicorn activos."

# 3. Eliminar socket si aún existe
if [ -S "$SOCK_FILE" ]; then
    echo "🧹 Eliminando socket: $SOCK_FILE"
    rm -f "$SOCK_FILE"
else
    echo "🧼 Socket ya no existe, limpio."
fi

# 4. Detener NGINX si está activo
echo "🌐 Deteniendo NGINX..."
sudo systemctl stop nginx || echo "⚠️  NGINX ya estaba detenido."


# === Liberar puertos usados por Gunicorn o procesos colgados ===
echo "🔓 Liberando puertos usados (8000–8090)..."

for port in $(seq 8000 8090); do
    PIDS=$(sudo lsof -ti tcp:$port)
    if [ ! -z "$PIDS" ]; then
        echo "⚠ Puerto $port en uso por PID(s): $PIDS"
        for pid in $PIDS; do
            sudo kill -9 $pid && echo "🔪 Proceso $pid eliminado."
        done
    fi
done

# === Matar procesos Gunicorn explícitamente si quedaran colgados ===
RESIDUAL=$(pgrep -f "gunicorn.*bank_ghost")
if [ ! -z "$RESIDUAL" ]; then
    echo "⚠ Procesos Gunicorn activos: $RESIDUAL"
    echo "$RESIDUAL" | xargs sudo kill -9
    echo "✅ Gunicorn residual eliminado."
else
    echo "✅ No hay procesos gunicorn activos."
fi


echo "✅ Todo detenido y limpio. Ghost Recon ha sido apagado correctamente."


# =========================== z03 ===========================