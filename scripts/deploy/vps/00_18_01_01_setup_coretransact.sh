#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"
# Auto-reinvoca con bash si no está corriendo con bashif [ -z "$BASH_VERSION" ]; then
#     exec bash "$0" "$@"
# fi

# # Función para autolimpieza de huella SSH
# verificar_huella_ssh() {
#     local host="$1"
#     echo "🔍 Verificando huella SSH para $host..."
#     ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 "$host" "exit" >/dev/null 2>&1 || {
#         echo "⚠️  Posible conflicto de huella, limpiando..."
#         ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
#     }
# }
# #!/usr/bin/env bash
# set -e

# # === Variables (ajustables) ===
# IP_VPS="80.78.30.242"
# PORT_VPS="22"

# verificar_huella_ssh "$IP_VPS"

REMOTE_USER="markmur88"
APP_USER="markmur88"

REPO_DIR="api_bank_heroku"

DB_NAME="mydatabase"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_HOST="localhost"

REPO_GIT="git@github.com:${APP_USER}/${REPO_DIR}.git"

EMAIL_SSL="netghostx90@protonmail.com"

SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"


echo "📦 Instalando dependencias iniciales en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e -x


echo "👤 Creando usuario $APP_USER..."

# Define la contraseña directamente (podés cambiarla desde una variable de entorno si querés mayor seguridad)
APP_PASSWD="Ptf8454Jd55"

useradd -m -s /bin/bash "$APP_USER"
echo "$APP_USER:$APP_PASSWD" | chpasswd
usermod -aG sudo "$APP_USER"
echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$APP_USER

# Configuración de SSH
mkdir -p /home/$APP_USER/.ssh
cp /root/.ssh/authorized_keys /home/$APP_USER/.ssh/
chown -R $APP_USER:$APP_USER /home/$APP_USER/.ssh
chmod 700 /home/$APP_USER/.ssh
chmod 600 /home/$APP_USER/.ssh/authorized_keys

# Cambia automáticamente al nuevo usuario
echo "✅ Usuario $APP_USER creado con acceso sudo y SSH configurado."
su - "$APP_USER"


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
sudo usermod -aG postgres markmur88

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
sudo hostnamectl set-hostname coretransapi


echo "🧭 Configurando Supervisor para Gunicorn..."
sudo cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
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
sudo certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m $EMAIL_SSL --redirect


echo "🔄 Reiniciando Nginx..."
sudo nginx -t && sudo systemctl reload nginx


echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now


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