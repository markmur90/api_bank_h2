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
# ⚠️ Detectar y cambiar a usuario no-root si es necesario


if [[ "$EUID" -eq 0 && "$SUDO_USER" != "markmur88" ]]; then
    echo "🧍 Ejecutando como root. Cambiando a usuario 'markmur88'..."
    
    # # Solicita la contraseña de sudo
    # read -s -p "🔐 Ingresá la contraseña de 'markmur88': " SUDO_PASS
    # echo
    SUDO_PASS="Ptf8454Jd55"
    # Ejecuta el script como markmur88 usando sudo con contraseña
    echo "$SUDO_PASS" | sudo -S -u markmur88 "$0" "$@"
    exit 0
fi

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
        ssh-keygen -f "/home/markmur88/.ssh/known_hosts" -R "$host" >/dev/null
    }

}
#!/usr/bin/env bash
set -e -x

SCRIPT_NAME="$(basename "$0")"

PROJECT_DIR="$BASE_DIR"


# === Variables (ajustables) ===
IP_VPS="80.78.30.242"
verificar_huella_ssh "$IP_VPS"
PORT_VPS="22"
REMOTE_USER="markmur88"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
APP_USER="markmur88"
REPO_GIT="https://github.com/markmur90/api_bank_heroku.git"
DB_USER="markmur88"
DB_PASS="Ptf8454Jd55"
DB_NAME="mydatabase"
EMAIL_SSL="netghostx90@protonmail.com"

echo "🚀 Continuando despliegue completo en $IP_VPS..."

ssh -i "$SSH_KEY" -p "$PORT_VPS" "$REMOTE_USER@$IP_VPS" bash -s <<EOF
set -e

# echo "🔄 Cambiando puerto SSH..."
# sed -i "s/^#Port 22/Port 49222/" /etc/ssh/sshd_config
# sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
# systemctl restart sshd

echo "📥 Clonando proyecto Django..."
sudo -u $APP_USER git clone $REPO_GIT /home/$APP_USER/api_bank_heroku

echo "🐍 Configurando entorno virtual..."
sudo -u $APP_USER python3 -m venv /home/$APP_USER/envAPP
source /home/$APP_USER/envAPP/bin/activate
pip install --upgrade pip
pip install -r /home/$APP_USER/api_bank_heroku/requirements.txt

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
cd /home/$APP_USER/api_bank_heroku
source /home/$APP_USER/envAPP/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
chown -R $APP_USER:www-data /home/$APP_USER/api_bank_heroku

echo "🧭 Configurando Supervisor para Gunicorn..."
cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
[program:coretransapi]
directory=/home/$APP_USER/api_bank_heroku
command=/home/$APP_USER/envAPP/bin/gunicorn config.wsgi:application --bind unix:/home/$APP_USER/api_bank_heroku/api.sock --workers 3
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
        alias /home/$APP_USER/api_bank_heroku/static/;
    }

    location /media/ {
        alias /home/$APP_USER/api_bank_heroku/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/$APP_USER/api_bank_heroku/api.sock;
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