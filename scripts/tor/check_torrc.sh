#!/usr/bin/env bash

echo -e "\n🔍 Verificando configuración de Tor..."

# Verificar si el servicio Tor está activo
if systemctl is-active --quiet tor; then
    echo -e "✅ Tor está activo."
else
    echo -e "❌ Tor no está activo. Iniciando servicio..."
    sudo systemctl start tor
fi

# Verificar existencia del archivo torrc
TORRC_PATH="/etc/tor/torrc"
if [ -f "$TORRC_PATH" ]; then
    echo -e "✅ Archivo de configuración torrc encontrado en $TORRC_PATH."
else
    echo -e "❌ Archivo de configuración torrc no encontrado en $TORRC_PATH."
    exit 1
fi

# Verificar existencia del servicio oculto
HIDDEN_SERVICE_DIR="/var/lib/tor/hidden_service"
if [ -d "$HIDDEN_SERVICE_DIR" ]; then
    echo -e "✅ Directorio de servicio oculto encontrado."
    if [ -f "$HIDDEN_SERVICE_DIR/hostname" ]; then
        echo -e "🧅 Dirección .onion: $(cat $HIDDEN_SERVICE_DIR/hostname)"
    else
        echo -e "⚠️ Archivo hostname no encontrado en el directorio de servicio oculto."
    fi
else
    echo -e "❌ Directorio de servicio oculto no encontrado en $HIDDEN_SERVICE_DIR."
fi

# Verificar puertos en uso
echo -e "\n📡 Puertos en uso por Tor:"
sudo netstat -tulnp | grep tor || echo "No se encontraron puertos en uso por Tor."

echo -e "\n✅ Verificación completada."
