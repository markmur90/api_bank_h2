#!/bin/bash
set -euo pipefail

HSDIR="/var/lib/tor/hidden_service"
TORRC="/etc/tor/torrc"
OWNER="debian-tor"
GROUP="debian-tor"
MAX_WAIT=30

echo "🔁 Reiniciando servicio Tor..."
sudo systemctl restart tor

echo "⌛ Esperando a que se genere el servicio oculto..."
for i in $(seq 1 $MAX_WAIT); do
  if [[ -f "$HSDIR/hostname" ]]; then
    echo "✅ Servicio oculto generado:"
    sudo cat "$HSDIR/hostname"
    break
  fi
  sleep 1
done

if [[ ! -f "$HSDIR/hostname" ]]; then
  echo "❌ Timeout: no se generó el archivo hostname. Verificá el torrc y los logs de Tor."
  exit 1
fi

echo "🔐 Asegurando permisos del servicio oculto..."
# sudo chown -R "$OWNER:$GROUP" "$HSDIR"
# sudo chmod 700 "$HSDIR"

sudo chown -R markmur88 /var/lib/tor/hidden_service
sudo chmod 750 /var/lib/tor/hidden_service

echo "📄 Dirección Onion final:"
sudo cat "$HSDIR/hostname"

echo "📋 Logs recientes de Tor:"
sudo tail -n 20 /var/log/tor/notices.log
