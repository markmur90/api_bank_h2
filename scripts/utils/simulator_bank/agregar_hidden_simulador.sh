#!/bin/bash
set -e

TORRC="/etc/tor/torrc"
BACKUP="/etc/tor/torrc.bak_$(date +%Y%m%d_%H%M%S)"
HIDDEN_DIR="/var/lib/tor/hidden_service"
PORT=9180

echo "🔒 Haciendo backup de torrc en $BACKUP"
sudo cp "$TORRC" "$BACKUP"

if grep -q "$HIDDEN_DIR" "$TORRC"; then
    echo "✅ Configuración de servicio oculto ya existe."
else
    echo "➕ Agregando configuración para simulador bancario..."
    echo -e "\n# Servicio oculto Simulador Banco\nHiddenServiceDir $HIDDEN_DIR\nHiddenServicePort 80 127.0.0.1:$PORT" | sudo tee -a "$TORRC"
fi

echo "📁 Verificando carpeta de servicio oculto..."
sudo mkdir -p "$HIDDEN_DIR"
sudo chown -R debian-tor:debian-tor "$HIDDEN_DIR"
sudo chmod 700 "$HIDDEN_DIR"

echo "🔄 Reiniciando Tor..."
sudo systemctl restart tor

sleep 5
if [ -f "$HIDDEN_DIR/hostname" ]; then
    echo "🧅 Dirección Onion generada:"
    sudo cat "$HIDDEN_DIR/hostname"
else
    echo "❌ No se generó el archivo hostname. Revisá los logs de Tor."
fi
