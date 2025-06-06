#!/bin/bash

echo "🔍 Verificando estado de Tor..."
if ! systemctl is-active --quiet tor; then
    echo "❌ Tor no está activo. Iniciando..."
    sudo systemctl start tor
else
    echo "✅ Tor está activo."
fi

HS_DIR="/var/lib/tor/hidden_service"

echo "📁 Configurando directorio del servicio oculto en $HS_DIR"
sudo mkdir -p "$HS_DIR"
sudo chown -R debian-tor:debian-tor "$HS_DIR"
sudo chmod 700 "$HS_DIR"

echo "♻️ Reiniciando Tor..."
sudo systemctl restart tor

echo "⏳ Esperando 3 segundos para generación de .onion..."
sleep 3

if [[ -f "$HS_DIR/hostname" ]]; then
    ONION=$(sudo cat "$HS_DIR/hostname")
    echo "✅ Servicio .onion disponible: $ONION"
else
    echo "❌ No se generó el archivo hostname. Revisá los logs de Tor."
fi
