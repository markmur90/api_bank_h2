#!/bin/bash
set -e

PROJECT_NAME="bank_ghost"
# PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/"
VENV_DIR="$PROJECT_DIR/venv"
SOCK_FILE="ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
SUPERVISOR_CONF="/etc/supervisor/conf.d/${PROJECT_NAME}.conf"
NGINX_CONF="/etc/nginx/sites-available/${PROJECT_NAME}"
USER="markmur88"

echo "🔍 Detectando entorno..."

# Detectar si es Heroku por variable de entorno típica
if [[ "$DYNO" ]]; then
    echo "💜 Entorno Heroku detectado"
    echo "📦 Aplicando migraciones..."
    python manage.py migrate

    echo "🚀 Ejecutando Gunicorn..."
    exec gunicorn ${PROJECT_NAME}.wsgi --log-file -
    exit 0
fi

echo "🖥️ Entorno VPS / Local detectado"

# Crear usuario si no existe
if ! id "$USER" &>/dev/null; then
    echo "👤 Creando usuario $USER..."
    sudo useradd -m -s /bin/bash $USER
fi

# Crear entorno virtual si no existe
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 Creando entorno virtual..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# # Instalar requerimientos
# if [ -f requirements.txt ]; then
#     echo "📦 Instalando dependencias..."
#     pip install --upgrade pip
#     pip install -r requirements.txt
# else
#     pip install django gunicorn weasyprint
# fi

# Migraciones + estáticos
echo "🛠️ Aplicando migraciones..."
python manage.py makemigrations
python manage.py migrate
# python manage.py createsuperuser


echo "📁 Colectando archivos estáticos..."
python manage.py collectstatic --noinput

# Logs
# mkdir -p "$LOG_DIR"
# chown -R $USER:$USER "$LOG_DIR"
touch "$LOG_DIR/gunicorn.log" "$LOG_DIR/error.log"

# Supervisor config
echo "⚙️ Configurando Supervisor..."
sudo bash -c "cat > $SUPERVISOR_CONF" <<EOF
[program:$PROJECT_NAME]
directory=$PROJECT_DIR
command=$VENV_DIR/bin/gunicorn $PROJECT_NAME.wsgi:application --bind unix:/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock --workers 3
autostart=true
autorestart=true
stderr_logfile=$LOG_DIR/error.log
stdout_logfile=$LOG_DIR/gunicorn.log
user=$USER
environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8
EOF

# NGINX config
echo "🌐 Configurando NGINX..."
read -p "🌍 Ingresa tu dominio para HTTPS (o presiona Enter para omitir): " DOMINIO

sudo bash -c "cat > $NGINX_CONF" <<EOF
server {
    listen 80;
    server_name ${DOMINIO:-_};

    location /static/ {
        root $PROJECT_DIR;
    }

    location /media/ {
        root $PROJECT_DIR;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock;
    }
}
EOF

sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$PROJECT_NAME"

# Reinicio de servicios
sudo systemctl daemon-reexec
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart $PROJECT_NAME
sudo systemctl restart nginx

# Asegurar permisos del socket
echo "🔒 Ajustando permisos de /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock..."
if [ -S "/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock" ]; then
    chown markmur88:www-data "/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock"
    chmod +x "/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/ghost.sock"
fi


# Certbot si hay dominio
if [[ ! -z "$DOMINIO" ]]; then
    echo "🔐 Ejecutando Certbot para HTTPS..."
    sudo apt install certbot python3-certbot-nginx -y
    sudo certbot --nginx -d "$DOMINIO" --non-interactive --agree-tos -m admin@$DOMINIO

    echo "🔁 Redireccionando HTTP → HTTPS..."
    sudo bash -c "cat >> $NGINX_CONF" <<EOF

server {
    if (\$host = $DOMINIO) {
        return 301 https://\$host\$request_uri;
    }
    listen 80;
    server_name $DOMINIO;
}
EOF

    sudo systemctl reload nginx
    echo "✅ HTTPS activo para $DOMINIO"
fi

echo "🎉 Todo listo. Accede al sistema en: http://${DOMINIO:-localhost}/"