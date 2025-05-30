#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/deploy_coretransapi/deploy_coretransapi.log"
PROCESS_LOG="$SCRIPT_DIR/logs/deploy_coretransapi/process_deploy_coretransapi.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/deploy_coretransapi_.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"
mkdir -p "$(dirname "$LOG_DEPLOY")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

echo "🚀 Desplegando cambios en coretransapi..." | tee -a "$LOG_DEPLOY"

ssh -i ~/.ssh/vps_njalla_ed25519 -p 49222 root@80.78.30.188 <<'EOF'
set -e

# Parámetros
USER=root
MARK=markmur88
IP_VPS="80.78.30.188"
DIR_USR="/home/$MARK"
CLAVE_SSH="$DIR_USR/.ssh/vps_njalla_ed25519"
PROYECTO_DIR="$DIR_USR/coretransapi"
REPO_GIT="git@github.com:$MARK/api_bank_heroku.git"
VENV_DIR="$DIR_USR/envAPP"
LOG_DEPLOY="/var/log/deploy_coretransapi.log"
EMAIL_SSL="netghostx90@protonmail.com"

# 1. Subir clave pública SSH
echo "📤 Subiendo clave SSH..."
scp -i "$CLAVE_SSH" ~/.ssh/vps_njalla_ed25519.pub $USER@$IP_VPS:/root/coretransapi.pub

# 2. Configurar clave en el VPS
ssh -i "$CLAVE_SSH" $USER@$IP_VPS <<'EOF'
    set -e

    echo "📎 Aplicando clave pública a authorized_keys..."
    mkdir -p ~/.ssh
    cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    rm ~/coretransapi.pub

    echo "🧱 Instalando dependencias base..."
    apt update && apt upgrade -y
    apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx supervisor

    echo "🧱 Activando firewall UFW..."
    ufw --force enable
    ufw start
    for port in OpenSSH 22 80 443 5432 8000 9001 9050 9051 53 123 49222; do ufw allow "$port"; done
    ufw --force reload

    echo "🔄 Cambiando puerto SSH..."
    PORT=49222
    sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
    sed -i "s/^PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
    systemctl restart sshd
    echo "✅ SSH configurado en puerto $PORT"

    echo "🎯 Hostname y entorno inicial..."
    hostnamectl set-hostname coretransapi
    echo "coretransapi" > /etc/hostname

    echo "🌍 Zona horaria..."
    timedatectl set-timezone Europe/Berlin

    echo "👤 Creando usuario $MARK..."
    useradd -m -s /bin/bash $MARK
    usermod -aG sudo $MARK
    echo "$MARK ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$MARK

    echo "📥 Clonando proyecto Django..."
    sudo -u $MARK git clone $REPO_GIT $PROYECTO_DIR

    echo "🐍 Creando entorno virtual..."
    python3 -m venv $VENV_DIR
    source $VENV_DIR/bin/activate

    echo "📦 Instalando requirements..."
    pip install --upgrade pip
    pip install -r $PROYECTO_DIR/requirements.txt

    echo "🛠️ Configurando base de datos PostgreSQL..."
    systemctl enable postgresql
    systemctl start postgresql

    DB_NAME="mydatabase"
    DB_USER="markmur88"
    DB_PASS="Ptf8454Jd55"

    sudo -u postgres psql <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
            CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
        END IF;
    END
    \$\$;

    ALTER USER ${DB_USER} WITH CREATEDB CREATEROLE;
    GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
    GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};

    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';
    DROP DATABASE IF EXISTS ${DB_NAME};
    CREATE DATABASE ${DB_NAME};
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
    GRANT CONNECT, CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
    EOSQL

    echo "⚙️ Ejecutando migraciones y recolectando staticfiles..."
    cd $PROYECTO_DIR
    source $VENV_DIR/bin/activate
    python manage.py migrate
    python manage.py collectstatic --noinput

    echo "🔧 Configurando permisos de proyecto..."
    chown -R $MARK:www-data $PROYECTO_DIR

    echo "🧭 Configurando Supervisor para Gunicorn..."
    cat > /etc/supervisor/conf.d/coretransapi.conf <<SUPERVISOR
[program:coretransapi]
directory=$PROYECTO_DIR
command=$VENV_DIR/bin/gunicorn config.wsgi:application --bind unix:$PROYECTO_DIR/api.sock --workers 3
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log
user=$MARK
group=www-data
environment=PATH="$VENV_DIR/bin",DJANGO_SETTINGS_MODULE="config.settings"
SUPERVISOR

    supervisorctl reread
    supervisorctl update
    supervisorctl start coretransapi

    echo "🌐 Configurando Nginx..."
    cat > /etc/nginx/sites-available/coretransapi.conf <<NGINX
server {
    listen 80;
    server_name apih.coretransapi.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name apih.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/apih.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/apih.coretransapi.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;

    access_log /var/log/nginx/coretransapi_access.log;
    error_log /var/log/nginx/coretransapi_error.log;

    location /static/ {
        alias $PROYECTO_DIR/static/;
    }

    location /media/ {
        alias $PROYECTO_DIR/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$PROYECTO_DIR/api.sock;
    }
}
NGINX

    ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/coretransapi.conf
    rm -f /etc/nginx/sites-enabled/default

    if ! host apih.coretransapi.com | grep "$(hostname -I | awk '{print $1}')" > /dev/null; then
        echo "❌ El dominio no apunta al VPS. Aborta Certbot."
        exit 1
    fi

    echo "🔐 Solicitando certificado SSL con Certbot..."
    certbot --nginx -d apih.coretransapi.com --non-interactive --agree-tos -m $EMAIL_SSL --redirect || {
        echo "❌ Error en Certbot" >> $LOG_DEPLOY
        exit 1
    }

    echo "🔄 Reiniciando Nginx..."
    nginx -t && systemctl reload nginx

    echo "🧼 Limpieza y seguridad básica..."
    apt install fail2ban -y
    systemctl enable fail2ban --now

EOF
EOF

echo "✅ Tarea completada." | tee -a "$LOG_DEPLOY"
echo "✅ VPS coretransapi configurado correctamente."
echo "🛡️ Puedes conectarte con: ssh -i $CLAVE_SSH -p 49222 root@$IP_VPS"
