#!/bin/bash
echo "🔍 Verificando estado de Tor y servicio oculto del simulador..."

TOR_SERVICE="tor"
HIDDEN_DIR="/opt/simulador_banco/tor/hidden_service"
ONION_COPY="/home/markmur88/simulador_hostname.txt"

# Verificar si Tor está activo
if systemctl is-active --quiet "$TOR_SERVICE"; then
    echo "✅ Tor está activo."
else
    echo "❌ Tor no está activo. Iniciando servicio..."
    sudo systemctl start "$TOR_SERVICE"
fi

# Mostrar .onion si existe
if [ -f "$ONION_COPY" ]; then
    echo "🧅 Dirección .onion del simulador:"
    cat "$ONION_COPY"
    echo -e "\n🌐 Verificando conexión..."

    if torsocks curl -s "http://$(cat $ONION_COPY)" >/dev/null; then
        echo "✅ Conexión exitosa al servicio oculto"
    else
        echo "❌ No se pudo conectar al servicio oculto"
    fi
else
    echo "⚠️ No se encontró el archivo $ONION_COPY"
fi
