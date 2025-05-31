#!/bin/bash
set -e

echo "📎 Aplicando clave pública SSH..."
mkdir -p ~/.ssh
cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
rm ~/coretransapi.pub

echo "🧱 Instalando dependencias..."
apt update && apt upgrade -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx
