#!/bin/bash
set -e

SCRIPTS_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/scripts"

echo "🔄 Reiniciando Tor..."
sudo systemctl restart tor@default

echo "⏳ Esperando a que Tor arranque..."
sleep 3

echo "🛑 Deteniendo Gunicorn si está activo..."
pkill gunicorn || true
sleep 2

echo "🚀 Lanzando la dashboard..."
cd "$SCRIPTS_DIR"
./x03.sh
