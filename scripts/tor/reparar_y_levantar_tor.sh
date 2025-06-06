#!/bin/bash

echo "🛠 Reparando y levantando servicio Tor..."

# Paso 1: Matar procesos previos de Tor
echo "🔪 Terminando procesos previos de Tor..."
sudo pkill -f tor

# Paso 2: Limpiar sockets o lockfiles que bloqueen
echo "🧹 Limpiando archivos de bloqueo..."
sudo rm -f /var/run/tor/tor.pid
sudo rm -rf /var/lib/tor/hidden_service

# Paso 3: Crear HiddenServiceDir si no existe
echo "📁 Verificando directorio de servicio oculto..."
sudo mkdir -p /var/lib/tor/hidden_service
sudo chown -R debian-tor:debian-tor /var/lib/tor/hidden_service
sudo chmod 700 /var/lib/tor/hidden_service

# Paso 4: Validar configuración
echo "🧪 Validando archivo torrc..."
sudo tor -f /etc/tor/torrc --verify-config || { echo "❌ Error en la configuración de Tor."; exit 1; }

# Paso 5: Recargar systemd y reiniciar servicio
echo "🔄 Reiniciando servicio..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart tor

# Paso 6: Mostrar estado
echo "📋 Estado del servicio Tor:"
sudo systemctl status tor --no-pager

# Paso 7: Mostrar dirección .onion si está disponible
if [ -f /var/lib/tor/hidden_service/hostname ]; then
    echo "🧅 Dirección .onion activa:"
    cat /var/lib/tor/hidden_service/hostname
else
    echo "⚠️ No se encontró el archivo hostname aún."
fi
