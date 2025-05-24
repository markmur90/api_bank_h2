#!/usr/bin/env bash
set -e

VPS_USER="markmur88"
VPS_IP="80.78.30.188"

echo "📡 Conectando a VPS $VPS_USER@$VPS_IP..."
ssh "$VPS_USER@$VPS_IP" bash << 'EOF'
echo "🩺 Uptime:"
uptime
echo ""

echo "🧠 Memoria:"
free -h
echo ""

echo "🗂 Espacio en disco:"
df -h /
echo ""

echo "🔥 Procesos Gunicorn:"
ps aux | grep gunicorn | grep -v grep
echo ""

echo "🌐 Estado Nginx y Supervisor:"
sudo systemctl status nginx | grep Active
sudo systemctl status supervisor | grep Active
EOF
