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

REPO_DIR="api_bank_heroku"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

REPO_GIT="git@github.com:${APP_USER}/${REPO_DIR}.git"

EMAIL_SSL="netghostx90@protonmail.com"

SSH_KEY="$HOME/.ssh/vps_njalla_nueva"


echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s 
set -e


echo "👤 Creando usuario markmur88..."

# Define la contraseña directamente (podés cambiarla desde una variable de entorno si querés mayor seguridad)
APP_PASSWD="Ptf8454Jd55"

useradd -m -s /bin/bash "markmur88"
echo "markmur88:$APP_PASSWD" | chpasswd
usermod -aG sudo "markmur88"
echo "markmur88 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/markmur88

# Configuración de SSH
mkdir -p /home/markmur88/.ssh
cp /root/.ssh/authorized_keys /home/markmur88/.ssh/
chown -R markmur88:markmur88 /home/markmur88/.ssh
chmod 700 /home/markmur88/.ssh
chmod 600 /home/markmur88/.ssh/authorized_keys

# Cambia automáticamente al nuevo usuario
echo "✅ Usuario markmur88 creado con acceso sudo y SSH configurado."
su - "markmur88"


echo "📥 Clonando proyecto Django..."
git clone "$REPO_GIT" /home/markmur88/api_bank_heroku


echo "🐍 Configurando entorno virtual..."
python3 -m venv /home/markmur88/envAPP
source /home/markmur88/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/markmur88/api_bank_heroku/requirements.txt


echo "🛠 Configurando base de datos PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo usermod -aG postgres markmur88




sudo -u postgres psql
DO \$\$
BEGIN
    -- Verificar si el usuario ya existe
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'markmur88') THEN
        CREATE USER markmur88 WITH PASSWORD 'Ptf8454Jd55';
    END IF;
END
\$\$;
-- Asignar permisos al usuario
ALTER USER markmur88 WITH SUPERUSER;
GRANT USAGE, CREATE ON SCHEMA public TO markmur88;
GRANT ALL PRIVILEGES ON SCHEMA public TO markmur88;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO markmur88;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO markmur88;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO markmur88;
CREATE DATABASE mydatabase;
GRANT ALL PRIVILEGES ON DATABASE mydatabase TO markmur88;
GRANT CONNECT ON DATABASE mydatabase TO markmur88;
GRANT CREATE ON DATABASE mydatabase TO markmur88;





echo "⚙ Migraciones y archivos estáticos..."
cd /home/markmur88/api_bank_heroku
source /home/markmur88/envAPP/bin/activate
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
python manage.py makemigrations
python manage.py migrate
python manage.py collectstatic --noinput




chown -R markmur88:www-data /home/markmur88/api_bank_heroku


echo "🎯 Hostname y zona horaria..."
sudo hostnamectl set-hostname coretransapi


echo "🧭 Configurando Supervisor para Gunicorn..."
sudo mkdir -p /var/log/supervisor
sudo chown root:adm /var/log/supervisor
sudo chmod 750 /var/log/supervisor

sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/api_bank_heroku
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \
  --bind unix:/home/markmur88/api_bank_heroku/api.sock \
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

# Asegúrate de incluir todas las vars de entorno que necesites:
environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="config.settings",\
  DJANGO_ENV="production"
SUPERVISOR

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start coretransapi




echo "🌐 Configurando Nginx..."
sudo cat > /etc/nginx/sites-available/coretransapi.conf <<NGINX
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
        alias /home/markmur88/api_bank_heroku/static/;
    }

    location /media/ {
        alias /home/markmur88/api_bank_heroku/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/markmur88/api_bank_heroku/api.sock;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

sudo nginx -t

VPS_IPV4=$(hostname -I | awk '{print $1}')
DNS_IP=$(dig +short api.coretransapi.com | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)

if [[ "$DNS_IP" != "$VPS_IPV4" ]]; then
    echo "❌ DNS ($DNS_IP) no coincide con IP local ($VPS_IPV4). Abortando Certbot."
    exit 1
fi



echo "🔐 Solicitando certificado SSL..."
sudo certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m netghostx90@protonmail.com --redirect


echo "🔄 Reiniciando Nginx..."
sudo nginx -t && sudo systemctl reload nginx


echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now
sudo systemctl reload fail2ban

echo "🧱 Activando firewall UFW..."
# Paso 1: Permitir el puerto SSH remoto antes de cambiar políticas
sudo ufw allow 22/tcp        # ⚠️ Primero permitir el acceso actual
sudo ufw limit 22/tcp        # Mitigación básica de fuerza bruta

# Paso 2: Configurar políticas por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Paso 3: Agregar el resto de reglas (HTTP, HTTPS, servicios locales, etc.)
# 🌐 Accesos esenciales
sudo ufw allow 80/tcp         # HTTP
sudo ufw allow 443/tcp        # HTTPS
sudo ufw allow 49222/tcp      # SSH personalizado (limitado)
sudo ufw limit 49222/tcp      # SSH con rate limiting (protección fuerza bruta)
# 🔒 PostgreSQL solo local
sudo ufw allow from 127.0.0.1 to any port 5432
# 🐍 Gunicorn local
sudo ufw allow from 127.0.0.1 to any port 8000
sudo ufw allow from 127.0.0.1 to any port 8001
sudo ufw allow from 127.0.0.1 to any port 8011
# ⚙️ Supervisor y servicios internos
sudo ufw allow from 127.0.0.1 to any port 9001
sudo ufw allow from 127.0.0.1 to any port 9050
sudo ufw allow from 127.0.0.1 to any port 9051
# 🌍 DNS y NTP salientes
sudo ufw allow out 53
sudo ufw allow out 123/udp
sudo ufw allow out to any port 443 proto tcp
# 🧹 Limpieza (opcional si venís con reglas anteriores)
sudo ufw delete allow 22/tcp || true
sudo ufw delete allow 22/tcp (v6) || true
sudo ufw delete allow 2222/tcp || true
sudo ufw delete allow 2222/tcp (v6) || true

# Paso 4: Activar UFW si aún no está
sudo ufw enable


echo "🛠 Configurando SSH..."
sudo systemctl enable ssh

echo "🔄 Cambiando puerto SSH..."
sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config

sudo systemctl start ssh
sudo systemctl restart sshd

EOF

echo "✅ Fase 1 completada. Ahora conectate por el puerto 49222 y ejecutá la fase 2."