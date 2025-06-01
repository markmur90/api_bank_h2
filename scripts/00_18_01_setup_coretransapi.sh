#!/usr/bin/env bash
set -e

APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_heroku.git"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
EMAIL_SSL="netghostx90@protonmail.com"
REPO_DIR="api_bank_heroku"

IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
REMOTE_USER="root"

echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

echo "🧱 Instalando dependencias base..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl build-essential ufw fail2ban \
    python3 python3-pip python3-venv python3-dev libpq-dev \
    postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor

sudo apt install -y \
  libcairo2 \
  libpango-1.0-0 \
  libpangoft2-1.0-0 \
  libpangocairo-1.0-0 \
  libgdk-pixbuf2.0-0 \
  libffi-dev \
  shared-mime-info \
  libxml2 \
  libxml2-dev \
  libxslt1-dev
source ~/envAPP/bin/activate
pip install --no-cache-dir --force-reinstall weasyprint


echo "🧱 Activando firewall UFW..."
sudo ufw default allow incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
sudo ufw allow out to any port 443
sudo ufw allow from 127.0.0.1 to any port 5432
sudo ufw allow from 127.0.0.1 to any port 9001
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
sudo ufw allow out 53
sudo ufw allow out 123/udp
sudo ufw default allow incoming
sudo ufw default deny outgoing
sudo ufw logging full
sudo ufw enable

echo "📥 Clonando proyecto Django..."
git clone "$REPO_GIT" /home/$APP_USER/$REPO_DIR

echo "🐍 Configurando entorno virtual..."
python3 -m venv /home/$APP_USER/envAPP
source /home/$APP_USER/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/$APP_USER/$REPO_DIR/requirements.txt





echo "🛠 Configurando base de datos PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

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

echo "⚙ Migraciones y archivos estáticos..."
cd /home/$APP_USER/$REPO_DIR
source /home/$APP_USER/envAPP/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
sudo chown -R $APP_USER:www-data /home/$APP_USER/$REPO_DIR

echo "🧭 Configurando Supervisor para Gunicorn..."
cat > /etc/supervisor/conf.d/$REPO_DIR.conf <<SUPERVISOR
[program:$REPO_DIR]
directory=/home/$APP_USER/$REPO_DIR
command=/home/$APP_USER/envAPP/bin/gunicorn config.wsgi:application --bind unix:/home/$APP_USER/$REPO_DIR/api.sock --workers 3
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/$REPO_DIR.err.log
stdout_logfile=/var/log/supervisor/$REPO_DIR.out.log
user=$APP_USER
group=www-data
environment=PATH="/home/$APP_USER/envAPP/bin",DJANGO_SETTINGS_MODULE="config.settings"
SUPERVISOR

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start $REPO_DIR

echo "🌐 Configurando Nginx..."
cat > /etc/nginx/sites-available/$REPO_DIR.conf <<NGINX
server {
    listen 80;
    server_name api.$REPO_DIR.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.$REPO_DIR.com;

    ssl_certificate /etc/letsencrypt/live/api.$REPO_DIR.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.$REPO_DIR.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;

    location /static/ {
        alias /home/$APP_USER/$REPO_DIR/static/;
    }

    location /media/ {
        alias /home/$APP_USER/$REPO_DIR/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/$APP_USER/$REPO_DIR/api.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/$REPO_DIR.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "🔐 Solicitando certificado SSL..."
sudo certbot --nginx -d api.$REPO_DIR.com --non-interactive --agree-tos -m $EMAIL_SSL --redirect

echo "🔄 Reiniciando Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now
EOF
