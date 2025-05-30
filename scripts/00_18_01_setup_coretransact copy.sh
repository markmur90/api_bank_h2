#!/bin/bash

set -e
exec > >(tee -i /root/deploy_coretransapi.log)
exec 2>&1

echo "🔐 Iniciando configuración básica para VPS: coretransapi"

USER=root
IP_VPS="80.78.30.188"  # IP del VPS
IP_ADMIN="203.0.113.42"  # Reemplazá con tu IP pública real
CLAVE_SSH="$HOME/.ssh/vps_njalla_ed25519"
PROYECTO_DIR="/home/markmur88/coretransapi"
REPO_GIT="git@github.com:markmur88/api_bank_heroku.git"
VENV_DIR="/home/markmur88/envAPP"

echo "📎 Subiendo clave pública SSH..."
scp -i "$CLAVE_SSH" ~/.ssh/vps_njalla_ed25519.pub $USER@$IP_VPS:/root/coretransapi.pub

ssh -i "$CLAVE_SSH" $USER@$IP_VPS << EOF
echo "🔑 Autorizando clave SSH..."
mkdir -p ~/.ssh
cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
rm ~/coretransapi.pub

echo "🧱 Instalando dependencias base..."
apt update && apt upgrade -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx acl

echo "🧯 Configurando firewall UFW..."
ufw --force reset
ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw allow 8000
ufw allow from $IP_ADMIN to any port 49222 proto tcp
ufw --force enable

echo "📁 Backup de sshd_config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak_\$(date +%F_%T)

echo "🔁 Configurando SSH en puerto 49222..."
sed -i 's/^#Port 22/Port 22\\nPort 49222/' /etc/ssh/sshd_config
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
echo "markmur88 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/markmur88

echo "📥 Clonando proyecto Django..."
sudo -u markmur88 git clone $REPO_GIT $PROYECTO_DIR

echo "🐍 Creando entorno virtual..."
sudo -u markmur88 python3 -m venv $VENV_DIR
sudo -u markmur88 bash -c "source $VENV_DIR/bin/activate && pip install --upgrade pip && pip install -r $PROYECTO_DIR/requirements.txt"

echo "🛠️ Configurando base de datos PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE mydatabase;"
sudo -u postgres psql -c "CREATE USER markmur88 WITH PASSWORD 'Ptf8454Jd55';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET client_encoding TO 'utf8';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET default_transaction_isolation TO 'read committed';"
sudo -u postgres psql -c "ALTER ROLE markmur88 SET timezone TO 'Europe/Madrid';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE mydatabase TO markmur88;"

echo "⚙️ Ejecutando migraciones y staticfiles..."
sudo -u markmur88 bash -c "source $VENV_DIR/bin/activate && cd $PROYECTO_DIR && python manage.py migrate && python manage.py collectstatic --noinput"

echo "🔧 Creando servicio Gunicorn..."
cat > /etc/systemd/system/gunicorn.service <<GEOF
[Unit]
Description=Gunicorn daemon para coretransapi
After=network.target

[Service]
User=markmur88
Group=www-data
WorkingDirectory=$PROYECTO_DIR
ExecStart=$VENV_DIR/bin/gunicorn --access-logfile - --workers 3 --bind unix:$PROYECTO_DIR/api.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
GEOF

chmod 644 /etc/systemd/system/gunicorn.service
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

echo "🌐 Configurando Nginx..."
cp $PROYECTO_DIR/scripts/nginx.conf /etc/nginx/sites-available/coretransapi.conf
ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/coretransapi.conf
rm -f /etc/nginx/sites-enabled/default

echo "🌐 Verificando que el dominio apih.coretransapi.com apunte a \$(hostname -I | awk '{print \$1}')"
if ! host apih.coretransapi.com | grep "\$(hostname -I | awk '{print \$1}')" > /dev/null; then
    echo "❌ El dominio no apunta al VPS. Aborta Certbot."
    exit 1
fi

echo "🔐 Solicitando certificado SSL con Certbot..."
certbot --nginx -d apih.coretransapi.com --non-interactive --agree-tos -m netghostx90@protonmail.com --redirect

echo "🔄 Validando configuración Nginx y recargando..."
nginx -t || { echo "❌ Error en configuración Nginx. Abortando."; exit 1; }
systemctl reload nginx

ls -l /etc/letsencrypt/live/apih.coretransapi.com

echo "✅ VPS coretransapi desplegado y operativo con HTTPS, Gunicorn y Django."
EOF
