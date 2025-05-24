#!/bin/bash

set -e

echo "🔐 Iniciando configuración básica para VPS: coretransapi"

USER=root
IP_VPS="80.78.30.188"
CLAVE_SSH="$HOME/.ssh/vps_njalla_ed25519"
PROYECTO_DIR="/root/api_bank_h2"
REPO_GIT="git@github.com:markmur88/api_bank_heroku.git"
VENV_DIR="/root/venvAPI"

echo "📎 Subiendo clave pública SSH..."
scp -i "$CLAVE_SSH" ~/.ssh/vps_njalla_ed25519.pub $USER@$IP_VPS:/root/coretransapi.pub

ssh -i "$CLAVE_SSH" $USER@$IP_VPS << 'EOF'
echo "🔑 Autorizando clave SSH..."
mkdir -p ~/.ssh
cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
rm ~/coretransapi.pub

echo "🧱 Instalando dependencias base..."
apt update && apt upgrade -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx

echo "🧯 Configurando firewall UFW..."
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw allow 8000
ufw allow 49222
ufw --force enable
ufw --force reset

echo "🔁 Configurando SSH en puerto 49222..."
sed -i 's/^#Port 22/Port 22\nPort 49222/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd

echo "🎯 Configurando hostname..."
hostnamectl set-hostname coretransapi
echo "coretransapi" > /etc/hostname

echo "🌍 Configurando zona horaria..."
timedatectl set-timezone Europe/Madrid

echo "👤 Creando usuario markmur88..."
useradd -m -s /bin/bash markmur88
usermod -aG sudo markmur88
echo "markmur88 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/markmur88

echo "📥 Clonando proyecto Django..."
cd /root
git clone $REPO_GIT

echo "🐍 Creando entorno virtual..."
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

echo "📦 Instalando requirements..."
pip install --upgrade pip
pip install -r $PROYECTO_DIR/requirements.txt

echo "🛠️ Configurando base de datos PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE mydatabase;"
sudo -u postgres psql -c "CREATE USER markmur88 WITH PASSWORD 'Ptf8454Jd55';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET timezone TO 'Europe/Madrid';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydatabase TO markmur88;"

echo "⚙️ Ejecutando migraciones y recolectando staticfiles..."
cd $PROYECTO_DIR
source $VENV_DIR/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput

echo "🔧 Creando servicio Gunicorn..."
cat > /etc/systemd/system/gunicorn.service <<GEOF
[Unit]
Description=Gunicorn daemon para api_bank_h2
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=$PROYECTO_DIR
ExecStart=$VENV_DIR/bin/gunicorn --access-logfile - --workers 3 --bind unix:$PROYECTO_DIR/api.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
GEOF

systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

echo "🌐 Configurando Nginx..."
cp $PROYECTO_DIR/sripts/nginx.conf /etc/nginx/sites-available/api_bank_h2.conf
ln -sf /etc/nginx/sites-available/api_bank_h2.conf /etc/nginx/sites-enabled/api_bank_h2.conf
rm -f /etc/nginx/sites-enabled/default

echo "🔐 Solicitando certificado SSL con Certbot..."
certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m admin@coretransapi.com --redirect

echo "🔄 Reiniciando Nginx..."
nginx -t && systemctl reload nginx

ls -l /etc/letsencrypt/live/api.coretransapi.com

nginx -t && systemctl reload nginx

echo "✅ VPS coretransapi desplegado y operativo con HTTPS, Gunicorn y Django."
EOF
