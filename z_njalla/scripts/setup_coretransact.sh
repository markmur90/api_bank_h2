#!/bin/bash

set -e
echo "🔐 Iniciando configuración básica para VPS: coretransapi"

# Parámetros
USER=root
MARK=markmur88
IP_VPS="80.78.30.188"
DIR_USR="/home/$MARK"
CLAVE_SSH="$DIR_USR/.ssh/vps_njalla_ed25519"
PROYECTO_DIR="$DIR_USR/coretransapi"
REPO_GIT="git@github.com:$MARK/api_bank_heroku.git"
VENV_DIR="$DIR_USR/envAPP"

# 1. Subir clave pública SSH
echo "📤 Subiendo clave SSH..."
scp -i "$CLAVE_SSH" ~/.ssh/vps_njalla_ed25519.pub $USER@$IP_VPS:/root/coretransapi.pub

# 2. Configurar clave en el VPS
ssh -i "$CLAVE_SSH" $USER@$IP_VPS <<'EOF'
    echo "📎 Aplicando clave pública a authorized_keys..."
    mkdir -p ~/.ssh
    cat ~/coretransapi.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
    rm ~/coretransapi.pub


    echo "🧱 Instalando dependencias base..."
    apt update && apt upgrade -y
    apt install -y git curl build-essential ufw fail2ban python3 python3-pip python3-venv python3-dev libpq-dev postgresql postgresql-contrib nginx certbot python3-certbot-nginx


    echo "🧱 Activando firewall UFW..."
    apt update && apt install ufw -y
    ufw --force enable
    ufw start
    ufw allow OpenSSH
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw allow 5432
    ufw allow 8000
    ufw allow 9001
    ufw allow 9050
    ufw allow 9051
    ufw allow 53
    ufw allow 443
    ufw allow 123
    ufw allow 49222
    ufw --force restart


    echo "🔄 Cambiando puerto SSH..."
    PORT=49222
    sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
    sed -i "s/^PermitRootLogin yes/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
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

    # === CREDENCIALES BASE DE DATOS ===
    DB_NAME="mydatabase"
    DB_USER="markmur88"
    DB_PASS="Ptf8454Jd55"

    sudo -u postgres psql <<-EOF
    DO \$\$
    BEGIN
        -- Verificar si el usuario ya existe
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
            CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
        END IF;
    END
    \$\$;

    #-- Asignar permisos al usuario
    ALTER USER ${DB_USER} WITH SUPERUSER;
    GRANT USAGE, CREATE ON SCHEMA public TO ${DB_USER};
    GRANT ALL PRIVILEGES ON SCHEMA public TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${DB_USER};
    EOF

    sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'" | grep -q 1
    if [ $? -eq 0 ]; then
        echo "La base de datos ${DB_NAME} existe. Eliminándola..." | tee -a $LOG_DEPLOY
        sudo -u postgres psql -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DB_NAME}';"
        sudo -u postgres psql -c "DROP DATABASE ${DB_NAME};"
    fi

    sudo -u postgres psql <<-EOF
    CREATE DATABASE ${DB_NAME};
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
    GRANT CONNECT ON DATABASE ${DB_NAME} TO ${DB_USER};
    GRANT CREATE ON DATABASE ${DB_NAME} TO ${DB_USER};
    EOF


    echo "⚙️ Ejecutando migraciones y recolectando staticfiles..."
    cd $PROYECTO_DIR
    source $VENV_DIR/bin/activate
    python manage.py migrate
    python manage.py collectstatic --noinput


    echo "🔧 Creando servicio Gunicorn..."
    cat > /etc/systemd/system/gunicorn.service <<GEOF
    [Unit]
    Description=Gunicorn daemon para coretransapi
    After=network.target

    chown -R $MARK:www-data $PROYECTO_DIR
    WorkingDirectory=$PROYECTO_DIR
    ExecStart=$VENV_DIR/bin/gunicorn --access-logfile - --workers 3 --bind unix:$PROYECTO_DIR/api.sock config.wsgi:application

    [Install]
    WantedBy=multi-user.target
    GEOF

    systemctl daemon-reload
    systemctl enable gunicorn
    systemctl start gunicorn


    echo "🌐 Configurando Nginx..."
    cp $PROYECTO_DIR/scripts/nginx.conf /etc/nginx/sites-available/coretransapi.conf
    ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/coretransapi.conf
    rm -f /etc/nginx/sites-enabled/default
    echo "🌐 Verificando que el dominio apih.coretransapi.com apunte a $(hostname -I | awk '{print $1}')"
    if ! host apih.coretransapi.com | grep "$(hostname -I | awk '{print $1}')" > /dev/null; then
        echo "❌ El dominio no apunta al VPS. Aborta Certbot."
        exit 1
    fi


    echo "🔐 Solicitando certificado SSL con Certbot..."
    certbot --nginx -d apih.coretransapi.com --non-interactive --agree-tos -m netghostx90@protonmail.com --redirect


    echo "🔄 Reiniciando Nginx..."
    nginx -t && systemctl reload nginx

    ls -l /etc/letsencrypt/live/apih.coretransapi.com

    nginx -t && systemctl reload nginx


    echo "🧼 Limpieza y seguridad básica..."
    apt install fail2ban -y
    systemctl enable fail2ban --now

EOF

echo "✅ VPS coretransapi configurado correctamente."
echo "🛡️ Puedes conectarte con: ssh -i $CLAVE_SSH -p 49222 root@IP_DEL_VPS"
