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
PORT_VPS="22"

verificar_huella_ssh "$IP_VPS"

REMOTE_USER="root"
APP_USER="markmur88"

REPO_GIT="https://github.com/markmur90/api_bank_heroku.git"
REPO_DIR="api_bank_heroku"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

EMAIL_SSL="netghostx90@protonmail.com"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"


echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e


echo "🧱 Instalando dependencias base..."
sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor openssh-server apt-transport-https ca-certificates


echo "🧱 Instalando dependencia TOR..."
curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo gpg --dearmor -o /usr/share/keyrings/tor-archive-keyring.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/tor-archive-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/tor.list

sudo apt-get update && sudo apt-get install -y tor deb.torproject.org-keyring && sudo systemctl enable tor && sudo systemctl start tor


echo "👤 Creando usuario $APP_USER..."
useradd -m -s /bin/bash $APP_USER
usermod -aG sudo $APP_USER
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$APP_USER
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys
su - $APP_USER


echo "👤 Creando usuario markmur88..."
useradd -m -s /bin/bash markmur88
usermod -aG sudo markmur88
echo "markmur88 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/markmur88

mkdir -p /home/markmur88/.ssh
cp /root/.ssh/authorized_keys /home/markmur88/.ssh/
chown -R markmur88:markmur88 /home/markmur88/.ssh
chmod 700 /home/markmur88/.ssh
chmod 600 /home/markmur88/.ssh/authorized_keys
su - markmur88

echo "🛠 Configurando SSH..."
sudo systemctl enable ssh
sudo systemctl start ssh


echo "📥 Clonando proyecto Django..."
git clone "$REPO_GIT" /home/$APP_USER/$REPO_DIR


echo "🐍 Configurando entorno virtual..."
python3 -m venv /home/$APP_USER/envAPP
source /home/$APP_USER/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/$APP_USER/$REPO_DIR/requirements.txt


echo "🛠 Configurando base de datos PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql
sudo -u postgres psql <<-EOSQL
DO \$\$
BEGIN
    -- Verificar si el usuario ya existe
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;
-- Asignar permisos al usuario
ALTER USER ${DB_USER} WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
CREATE DATABASE ${DB_NAME};
GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
EOSQL


echo "⚙ Migraciones y archivos estáticos..."
cd /home/$APP_USER/$REPO_DIR
source /home/$APP_USER/envAPP/bin/activate
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput


chown -R $APP_USER:www-data /home/$APP_USER/$REPO_DIR


echo "🎯 Hostname y zona horaria..."
hostnamectl set-hostname coretransapi


echo "🧭 Configurando Supervisor para Gunicorn..."
cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
[program:coretransapi]
directory=/home/$APP_USER/$REPO_DIR
command=/home/$APP_USER/envAPP/bin/gunicorn config.wsgi:application --bind unix:/home/$APP_USER/$REPO_DIR/api.sock --workers 3
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


echo "🧱 Activando firewall UFW..."
# Políticas seguras por defecto
sudo ufw default allow incoming
sudo ufw default allow outgoing

# Accesos remotos permitidos
sudo ufw allow 49222/tcp   # Puerto SSH personalizado
sudo ufw allow 22/tcp      # SSH fallback (si aún se usa)
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS

# Servicios internos / loopback
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8011
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 5432

# Honeypot SSH
sudo ufw allow 2222/tcp

# Supervisor local
sudo ufw allow from 127.0.0.1 to any port 9001

# Tor
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051

# Salida DNS, NTP, Push
sudo ufw allow out 53
sudo ufw allow out 123/udp
sudo ufw allow out to any port 443 proto tcp

# SSH
sudo ufw allow ssh

# Políticas seguras por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging full

# Activación
sudo ufw enable
sudo ufw reload


echo "🔄 Cambiando puerto SSH..."
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
systemctl restart sshd



EOF

echo "✅ Fase 1 completada. Ahora conectate por el puerto 49222 y ejecutá la fase 2."