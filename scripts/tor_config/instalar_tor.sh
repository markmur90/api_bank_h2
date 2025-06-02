#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Instalando Tor y configurando relay + servicio oculto..."

# Instalación
sudo apt update && sudo apt install -y tor

# Copiar configuración segura
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "$SCRIPT_DIR/torrc" /etc/tor/torrc

# Asegurar permisos
sudo chown -R debian-tor:debian-tor /var/lib/tor/hidden_service
sudo chmod 700 /var/lib/tor/hidden_service

# Reiniciar servicio
sudo systemctl enable tor
sudo systemctl restart tor

# Esperar que genere el hostname
echo "⌛ Esperando generación del servicio oculto..."
sleep 5

if [ -f /var/lib/tor/hidden_service/hostname ]; then
    echo "🧅 Dirección onion generada:"
    sudo cat /var/lib/tor/hidden_service/hostname
else
    echo "⚠️ Aún no se ha generado el hostname. Espera unos segundos y revisa con:"
    echo "   sudo cat /var/lib/tor/hidden_service/hostname"
fi
