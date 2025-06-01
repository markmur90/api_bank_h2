#!/usr/bin/env bash
set -e

echo "🔧 Instalando Tor y configurando relay + servicio oculto..."

# Instalación
apt update && apt install -y tor

# Copiar configuración segura
cp torrc /etc/tor/torrc

# Asegurar permisos
chown debian-tor:debian-tor /var/lib/tor/hidden_service -R
chmod 700 /var/lib/tor/hidden_service

# Reiniciar servicio
systemctl enable tor
systemctl restart tor

# Esperar que genere la dirección .onion
echo "⌛ Esperando generación del servicio oculto..."
sleep 5

echo "🧅 Dirección onion generada:"
cat /var/lib/tor/hidden_service/hostname
