#!/bin/bash
echo "🔍 Verificando estado de Tor y servicio oculto del simulador..."

TOR_SERVICE="tor"
HIDDEN_DIR="/opt/simulador_banco/tor/hidden_service"

# Verificar si Tor está activo
if systemctl is-active --quiet "$TOR_SERVICE"; then
    echo "✅ Tor está activo."
else
    echo "❌ Tor no está activo. Iniciando servicio..."
    sudo systemctl start "$TOR_SERVICE"
fi

# Mostrar .onion si existe
if [ -f "$HIDDEN_DIR/hostname" ]; then
    echo "🧅 Dirección .onion del simulador:"
    cat "$HIDDEN_DIR/hostname"
else
    echo "⚠️ No se encontró el archivo .onion en $HIDDEN_DIR/hostname"
fi
