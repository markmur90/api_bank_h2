#!/bin/bash
echo "🔧 Instalando simulador oculto con Tor..."

# Variables
HIDDEN_DIR="/var/lib/tor/hidden_service"
ONION_COPY="/home/markmur88/simulador_hostname.txt"

# Crear directorios y dar permisos
sudo mkdir -p "$HIDDEN_DIR"
sudo chown -R debian-tor:debian-tor "$HIDDEN_DIR"
sudo chmod 700 "$HIDDEN_DIR"

# Reiniciar tor
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart tor

# Esperar generación del .onion
sleep 5

# Copiar hostname legible localmente
if [ -f "$HIDDEN_DIR/hostname" ]; then
    sudo cp "$HIDDEN_DIR/hostname" "$ONION_COPY"
    sudo chown markmur88:markmur88 "$ONION_COPY"
    echo "✅ Dirección .onion disponible en $ONION_COPY"
else
    echo "⚠️ No se generó el archivo .onion aún."
fi
