#!/usr/bin/env bash
set -e -x

# Auto-reinvoca con bash si no está corriendo con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

REMOTE_USER="root"

APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_h2.git"
DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
EMAIL_SSL="netghostx90@protonmail.com"
REPO_DIR="api_bank_h2"

IP_VPS="80.78.30.242"
PORT_VPS="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"

echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e -x

# ==============================================================
# echo "👤 Creando usuario markmur88..."

# Define la contraseña directamente (podés cambiarla desde una variable de entorno si querés mayor seguridad)
# APP_PASSWD="Ptf8454Jd55"

# useradd -m -s /bin/bash "markmur88"
# echo "markmur88:$APP_PASSWD" | chpasswd
# usermod -aG sudo "markmur88"
# echo "markmur88 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/markmur88

# # Configuración de SSH
# mkdir -p /home/markmur88/.ssh
# cp /root/.ssh/authorized_keys /home/markmur88/.ssh/
# chown -R markmur88:markmur88 /home/markmur88/.ssh
# chmod 700 /home/markmur88/.ssh
# chmod 600 /home/markmur88/.ssh/authorized_keys
# ==============================================================


# Cambia automáticamente al nuevo usuario
# echo "✅ Usuario markmur88 creado con acceso sudo y SSH configurado."





sudo apt install -y zsh

chsh -s $(which zsh)
echo $SHELL



sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean



echo "🧱 Instalando dependencias de usuario..."
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git curl build-essential ufw fail2ban \
    python3 python3-pip python3-venv python3-dev libpq-dev \
    nginx certbot python3-certbot-nginx supervisor \
    libcairo2 libpango1.0-0 libpangoft2-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
    libffi-dev shared-mime-info libjpeg-dev zlib1g-dev libxml2 libxml2-dev libxslt1-dev \
    rsync


sudo apt-get install -y \
  libcairo2 \
  libpango-1.0-0 \
  libpangoft2-1.0-0 \
  libpangocairo-1.0-0 \
  libgdk-pixbuf2.0-0 \
  libffi-dev \
  shared-mime-info \
  libjpeg-dev \
  zlib1g-dev \
  libxml2 \
  libxml2-dev \
  libxslt1-dev





chown -R markmur88:www-data "/home/markmur88/$REPO_DIR"





echo "🎯 Hostname y zona horaria..."
sudo hostnamectl set-hostname coretransapi



# … (configuración previa de Supervisor, Gunicorn y Nginx en modo HTTP “temporal”) …

echo '🌐 Configurando Nginx (modo HTTP temporal para Certbot)…'
sudo tee /etc/nginx/sites-available/coretransapi.conf <<NGINXCONF
server {
    listen 80;
    server_name api.coretransapi.com;

    # Redirigir tráfico a Gunicorn
    location / {
        proxy_pass http://127.0.0.1:8000;
        include proxy_params;
    }
}
NGINXCONF

sudo ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

# —⇩ Bloque modificado ⇩—

echo '🔐 Obteniendo certificado SSL usando el plugin Nginx de Certbot...'
sudo certbot --nginx \
     --non-interactive \
     --agree-tos \
     -m "$EMAIL_SSL" \
     -d api.coretransapi.com

# —⇧ Fin de bloque modificado ⇧—

# … (continuación del script) …


echo "🧭 Configurando Supervisor para Gunicorn..."
sudo mkdir -p /var/log/supervisor
sudo chown root:adm /var/log/supervisor
sudo chmod 750 /var/log/supervisor

sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/api_bank_h2
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \
  --bind unix:/home/markmur88/api_bank_h2/api.sock \
  --workers 3
autostart=true
autorestart=true
# Ajusta el umask para que el socket sea accesible por grupo (www-data)
umask=007

stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log

# Ejecutar como usuario markmur88; grupo www-data permitirá que nginx acceda al socket
user=markmur88
group=www-data

# Variables de entorno necesarias para Django y la API bancaria
environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="config.settings",\
  DJANGO_ENV="production",\
  DEBUG="False",\
  ALLOWED_HOSTS="api.coretransapi.com",\
  SECRET_KEY="MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw",\
  REDIRECT_URI="https://api.coretransapi.com/oauth2/callback/",\
  ORIGIN="https://api.coretransapi.com",\
  CLIENT_ID="7c1e2c53-8cc3-4ea0-bdd6-b3423e76adc7",\
  CLIENT_SECRET="L88pwGelUZ5EV1YpfOG3e_r24M8YQ40-Gaay9HC4vt4RIl-Jz2QjtmcKxY8UpOWUInj9CoUILPBSF-H0QvUQqw",\
  TOKEN_URL="https://simulator-api.db.com:443/gw/oidc/token",\
  AUTHORIZE_URL="https://simulator-api.db.com:443/gw/oidc/authorize",\
  OTP_URL="https://simulator-api.db.com:443/gw/dbapi/others/onetimepasswords/v2/single",\
  AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/others/transactionAuthorization/v1/challenges",\
  API_URL="https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer",\
  SCOPE="sepa_credit_transfers",\
  TIMEOUT="3600",\
  TIMEOUT_REQUEST="3600"
SUPERVISOR

echo "🔄 Recargando Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update


# Si ya estaba arrancado, reiniciamos; si no, lo arrancamos
if sudo supervisorctl status coretransapi | grep -q "RUNNING"; then
    echo "⚠ coretransapi ya estaba arrancado; lo reiniciamos..."
    sudo supervisorctl restart coretransapi
else
    sudo supervisorctl start coretransapi
fi

echo "🌐 Configurando Nginx (modo HTTP temporal para Certbot)..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<'NGINX'
server {
    listen 80;
    server_name api.coretransapi.com;
    root /var/www/html;
}
NGINX

sudo ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "🔐 Solicitando certificado SSL con Certbot (modo standalone)..."
sudo certbot certonly --standalone --preferred-challenges http -d api.coretransapi.com --non-interactive --agree-tos -m "$EMAIL_SSL"

# Una vez emitido el certificado, ahora sí reemplazamos el virtual host con SSL
echo "🔧 Reemplazando config Nginx con soporte SSL..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<'NGINX'
server {
    listen 80;
    server_name api.coretransapi.com;
    return 301 https://$host$request_uri;
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
        alias /home/markmur88/api_bank_h2/static/;
    }

    location /media/ {
        alias /home/markmur88/api_bank_h2/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/markmur88/api_bank_h2/api.sock;
    }
}
NGINX

sudo nginx -t && sudo systemctl reload nginx

ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default



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
sudo ufw allow from 127.0.0.1 to any port 9180
sudo ufw allow out 53
sudo ufw allow out 123/udp
sudo ufw allow out to any port 443 proto tcp

# sudo ufw delete allow 22/tcp || true
# sudo ufw delete allow 22/tcp (v6) || true
# sudo ufw delete allow 2222/tcp || true
# sudo ufw delete allow 2222/tcp (v6) || true

echo "🛠 Configurando SSH..."
sudo systemctl enable ssh

echo "🔄 Cambiando puerto SSH..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

sudo systemctl start ssh
sudo systemctl restart sshd




su - "markmur88"

echo "🛠 Configurando base de datos PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo usermod -aG markmur88

# Comprobar si el directorio ya existe y eliminarlo si es así
if [ -d "/home/$APP_USER/$REPO_DIR" ]; then
    echo "El directorio $REPO_DIR ya existe. Eliminándolo..."
    sudo rm -rf "/home/$APP_USER/$REPO_DIR"
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
pip install --upgrade pip
pip install -r requirements.txt
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput

sudo cp /home/markmur88/api_bank_h2/scripts/.zshrc ~


EOF


echo "✅ Fase 1 completada. Ahora conectate por el puerto 49222 y ejecutá la fase 2."