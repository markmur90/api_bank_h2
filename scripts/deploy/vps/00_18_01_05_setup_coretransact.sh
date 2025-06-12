#!/usr/bin/env bash
set -e -x

# === Variables comunes ===
APP_USER="markmur88"
APP_PASSWD="Ptf8454Jd55"
REPO_GIT="https://github.com/markmur90/api_bank_h2.git"
REPO_DIR="api_bank_h2"
EMAIL_SSL="netghostx90@protonmail.com"

IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/${APP_USER}/.ssh/vps_njalla_nueva"
REMOTE_USER="root"

echo "🔑 Conectando a VPS $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<'EOF'
set -e


APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_h2.git"
REPO_DIR="api_bank_h2"
EMAIL_SSL="netghostx90@protonmail.com"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"

echo "🧱 Instalando dependencias de usuario..."
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git curl build-essential ufw fail2ban \
    python3 python3-pip python3-venv python3-dev libpq-dev \
    nginx certbot python3-certbot-nginx supervisor \
    libcairo2 libpango1.0-0 libpangoft2-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
    libffi-dev shared-mime-info libjpeg-dev zlib1g-dev libxml2 libxml2-dev libxslt1-dev \
    rsync

# Comprobar si el directorio ya existe y eliminarlo si es así
if [ -d "/home/$APP_USER/$REPO_DIR" ]; then
    echo "El directorio $REPO_DIR ya existe. Eliminándolo..."
    rm -rf "/home/$APP_USER/$REPO_DIR"
fi

echo "📥 Clonando repositorio Django..."
git clone "$REPO_GIT" "/home/$APP_USER/$REPO_DIR"

echo "🐍 Creando entorno virtual..."
python3 -m venv ~/envAPP
source ~/envAPP/bin/activate
pip install --upgrade pip
pip install -r ~/$REPO_DIR/requirements.txt

# Configurar PostgreSQL
sudo -u postgres psql <<SQL

DO \$\$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME') THEN
        CREATE DATABASE $DB_NAME;
    END IF;
END \$\$;

ALTER USER $DB_USER WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO $DB_USER;
GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;
SQL

echo "⚙ Migraciones y archivos estáticos..."
cd "/home/markmur88/$REPO_DIR"
source ~/envAPP/bin/activate
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput

chown -R markmur88:www-data "/home/markmur88/$REPO_DIR"


echo "🎯 Hostname y zona horaria..."
sudo hostnamectl set-hostname coretransapi

echo "🧭 Configurando Supervisor para Gunicorn..."
sudo mkdir -p /var/log/supervisor
sudo chown root:adm /var/log/supervisor
sudo chmod 750 /var/log/supervisor

sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/$REPO_DIR
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \
  --bind unix:/home/markmur88/$REPO_DIR/api.sock \
  --workers 3
autostart=true
autorestart=true
umask=007

stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log

user=markmur88
group=www-data

environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="config.settings",\
  DJANGO_ENV="production"
SUPERVISOR

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start coretransapi

echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<NGINX
server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" always;
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

    location /static/ {
        alias /home/markmur88/$REPO_DIR/static/;
    }

    location /media/ {
        alias /home/markmur88/$REPO_DIR/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/markmur88/$REPO_DIR/api.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

sudo nginx -t && sudo systemctl reload nginx

VPS_IPV4=$(hostname -I | awk '{print $1}')
DNS_IP=$(dig +short api.coretransapi.com | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)
[ -z "$DNS_IP" ] && { echo "❌ No se pudo resolver DNS."; exit 1; }

if [[ "$DNS_IP" != "$VPS_IPV4" ]]; then
    echo "❌ DNS ($DNS_IP) no coincide con IP local ($VPS_IPV4). Abortando Certbot."
    exit 1
fi

echo "🔐 Solicitando certificado SSL..."
sudo certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m $EMAIL_SSL --redirect

echo "🔄 Reiniciando Nginx..."
sudo nginx -t && sudo systemctl reload nginx

echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now
sudo systemctl reload fail2ban

echo "🧱 Activando firewall UFW..."
sudo ufw allow 49222/tcp
sudo ufw limit 49222/tcp
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp

sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

sudo ufw allow from 127.0.0.1 to any port 5432
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 9001
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
sudo ufw allow out 53
sudo ufw allow out 123/udp
sudo ufw allow out to any port 443 proto tcp

sudo ufw delete allow 22/tcp || true
sudo ufw delete allow 22/tcp (v6) || true
sudo ufw delete allow 2222/tcp || true
sudo ufw delete allow 2222/tcp (v6) || true

echo "🛠 Configurando SSH..."
sudo systemctl enable ssh

echo "🔄 Cambiando puerto SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

sudo systemctl start ssh
sudo systemctl restart sshd

echo "✅ Deploy completado. Ahora conectate por el puerto 49222."
EOF