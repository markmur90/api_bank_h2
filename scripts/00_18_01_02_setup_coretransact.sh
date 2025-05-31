#!/usr/bin/env bash

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Función para autolimpieza de huella SSH
verificar_huella_ssh() {
    local host="$1"
    echo "🔍 Verificando huella SSH para $host..."
    ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
        echo "⚠️  Posible conflicto de huella, limpiando..."
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$host" >/dev/null
    }
}
#!/usr/bin/env bash
set -e

# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
verificar_huella_ssh "$IP_VPS"
PORT_VPS="49222"
REMOTE_USER="root"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
APP_USER="deploy"
REPO_GIT="git@github.com:markmur88/coretransapi.git"
DB_USER="coretransuser"
DB_PASS="supersegura"
DB_NAME="coretransdb"
EMAIL_SSL="admin@coretransapi.com"

echo "🚀 Continuando despliegue completo en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

echo "🔄 Cambiando puerto SSH..."
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
systemctl restart sshd

echo "📥 Clonando proyecto Django..."
sudo -u $APP_USER git clone $REPO_GIT /home/$APP_USER/coretransapi

echo "🐍 Configurando entorno virtual..."
sudo -u $APP_USER python3 -m venv /home/$APP_USER/envAPP
source /home/$APP_USER/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/$APP_USER/coretransapi/requirements.txt

echo "🛠 Configurando base de datos PostgreSQL..."
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

echo "⚙ Migraciones y archivos estáticos..."
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