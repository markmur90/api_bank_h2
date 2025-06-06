#!/bin/bash

echo "🧅 Configurando servicio oculto para el simulador bancario..."

DIR_SERVICIO="/var/lib/tor/hidden_service"
TORRC="/etc/tor/torrc"
PUERTO_LOCAL=9180

# Verificar si ya existe
if grep -q "$DIR_SERVICIO" "$TORRC"; then
    echo "✅ Servicio oculto ya está configurado en torrc."
else
    echo "➕ Agregando configuración a torrc..."
    echo -e "\n# Servicio oculto Simulador Banco\nHiddenServiceDir $DIR_SERVICIO\nHiddenServicePort 80 127.0.0.1:$PUERTO_LOCAL" | sudo tee -a "$TORRC"
fi

# Crear directorio si no existe
if [ ! -d "$DIR_SERVICIO" ]; then
    echo "📁 Creando directorio de servicio oculto..."
    sudo mkdir -p "$DIR_SERVICIO"
    sudo chown -R debian-tor:debian-tor "$DIR_SERVICIO"
    sudo chmod 700 "$DIR_SERVICIO"
fi

# Reiniciar Tor para aplicar cambios
echo "🔄 Reiniciando Tor..."
sudo systemctl restart tor

# Esperar generación de la dirección .onion
sleep 5

# Mostrar la dirección .onion generada
if [ -f "$DIR_SERVICIO/hostname" ]; then
    echo "🧅 Dirección Onion generada:"
    cat "$DIR_SERVICIO/hostname"
else
    echo "❌ No se pudo generar el archivo hostname. Verificá los logs de Tor."
fi
