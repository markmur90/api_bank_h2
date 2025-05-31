#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/deploy_coretransapi/deploy_coretransapi.log"
PROCESS_LOG="$SCRIPT_DIR/logs/deploy_coretransapi/process_deploy_coretransapi.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/deploy_coretransapi_.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PROCESS_LOG")" "$(dirname "$LOG_DEPLOY")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

echo "🚀 Desplegando cambios en coretransapi..." | tee -a "$LOG_DEPLOY"

# Parámetros
IP_VPS="80.78.30.242"
PORT_VPS=22
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_USER=root
APP_USER=markmur88
EMAIL_SSL="netghostx90@protonmail.com"
REPO_GIT="git@github.com:$APP_USER/api_bank_heroku.git"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"  # generado dinámicamente

ssh -i "$SSH_KEY" -p $PORT_VPS $REMOTE_USER@$IP_VPS bash -s <<EOF
set -e

echo "🧱 Instalando dependencias base..."
apt update && apt upgrade -y
apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor

echo "🧱 Activando firewall UFW..."
ufw --force enable
ufw start
for port in OpenSSH 22 80 443 5432 8000 9001 9050 9051 53 123 49222; do ufw allow "\$port"; done
ufw --force reload

echo "🔄 Cambiando puerto SSH..."
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
systemctl restart sshd

echo "🎯 Hostname y zona horaria..."
hostnamectl set-hostname coretransapi
timedatectl set-timezone Europe/Berlin

echo "👤 Creando usuario $APP_USER..."
useradd -m -s /bin/bash $APP_USER
usermod -aG sudo $APP_USER
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$APP_USER
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys

echo "📥 Clonando proyecto Django..."
sudo -u $APP_USER git clone $REPO_GIT /home/$APP_USER/coretransapi

echo "🐍 Configurando entorno virtual..."
sudo -u $APP_USER python3 -m venv /home/$APP_USER/envAPP
source /home/$APP_USER/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/$APP_USER/coretransapi/requirements.txt

echo "🛠️ Configurando base de datos PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

sudo -u postgres psql <<EOSQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

ALTER USER ${DB_USER} WITH CREATEDB CREATEROLE;
DROP DATABASE IF EXISTS ${DB_NAME};
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOSQL

echo "⚙️ Migraciones y archivos estáticos..."
cd /home/$APP_USER/coretransapi
source /home/$APP_USER/envAPP/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
chown -R $APP_USER:www-data /home/$APP_USER/coretransapi

echo "🧭 Configurando Supervisor para Gunicorn..."
cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
[program:coretransapi]
directory=/home/$APP_USER/coretransapi
command=/home/$APP_USER/envAPP/bin/gunicorn config.wsgi:application --bind unix:/home/$APP_USER/coretransapi/api.sock --workers 3
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log
user=$APP_USER
group=www-data
environment=PATH="/home/$APP_USER/envAPP/bin",DJANGO_SETTINGS_MODULE="config.settings"
SUPERVISOR

supervisorctl reread
supervisorctl update
supervisorctl start coretransapi

echo "🌐 Configurando Nginx..."
cat > /etc/nginx/sites-available/coretransapi.conf <<NGINX
server {
    listen 80;
    server_name api.coretransapi.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;

    location /static/ {
        alias /home/$APP_USER/coretransapi/static/;
    }

    location /media/ {
        alias /home/$APP_USER/coretransapi/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/$APP_USER/coretransapi/api.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

if ! host api.coretransapi.com | grep "\$(hostname -I | awk '{print \$1}')" > /dev/null; then
    echo "❌ El dominio no apunta al VPS. Abortando Certbot."
    exit 1
fi

echo "🔐 Solicitando certificado SSL..."
certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m $EMAIL_SSL --redirect

echo "🔄 Reiniciando Nginx..."
nginx -t && systemctl reload nginx

echo "🧼 Activando Fail2Ban..."
systemctl enable fail2ban --now
EOF

echo "✅ VPS coretransapi configurado correctamente." | tee -a "$LOG_DEPLOY"
echo "🛡️ Puedes conectarte ahora con: ssh -i $SSH_KEY -p 49222 $REMOTE_USER@$IP_VPS"
