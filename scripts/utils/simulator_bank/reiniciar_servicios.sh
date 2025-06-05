#!/bin/bash
# 🔄 Reinicia servicios claves del simulador en el VPS

# Configuración SSH
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "🔧 Reiniciando servicios en el VPS ($VPS_USER@$VPS_IP)..."

ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" <<EOF
echo "🔄 Reiniciando Tor..."
sudo systemctl restart tor

echo "🔄 Reiniciando Gunicorn..."
sudo systemctl restart gunicorn

echo "🔄 Reiniciando Supervisor..."
sudo systemctl restart supervisor

echo "🔄 Reiniciando NGINX..."
sudo systemctl restart nginx

echo "✅ Todos los servicios fueron reiniciados exitosamente."
EOF
