#!/usr/bin/env bash
set -e

echo "🛠 Instalando dependencias en VPS..."

sudo apt update
sudo apt upgrade -y

echo "📦 Instalando Python y herramientas esenciales..."
sudo apt install -y python3 python3-pip python3-venv build-essential libpq-dev

echo "🐘 Instalando PostgreSQL y cliente..."
sudo apt install -y postgresql postgresql-contrib postgresql-client

echo "🧱 Instalando Nginx y herramientas de red..."
sudo apt install -y nginx curl git ufw fail2ban

echo "🔐 Instalando Certbot para SSL..."
sudo apt install -y certbot python3-certbot-nginx

sudo systemctl enable gunicorn
sudo systemctl restart gunicorn
sudo systemctl restart nginx


echo "✅ Dependencias instaladas correctamente."
