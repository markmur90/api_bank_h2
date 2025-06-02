#!/bin/bash

set -e

echo "🛠️ Iniciando configuración completa de Ghost Recon con HTTPS local..."

# === VARIABLES ===
PROJECT_NAME="bank_ghost"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
CERT_DIR="/etc/ssl/$PROJECT_NAME"
NGINX_CONF="/etc/nginx/sites-available/${PROJECT_NAME}_selfsigned"
NGINX_LINK="/etc/nginx/sites-enabled/${PROJECT_NAME}_selfsigned"
USER="markmur88"
GUNICORN_PORT=8011

# === FUNCIONES ===
function instalar_nginx_y_certificado {
    echo "📦 Instalando NGINX y creando certificado autofirmado..."
    sudo apt update && sudo apt install -y nginx openssl

    sudo mkdir -p "$CERT_DIR"
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$CERT_DIR/ghost.key" \
      -out "$CERT_DIR/ghost.crt" \
      -subj "/C=US/ST=None/L=None/O=GhostRecon/CN=localhost"
}

function configurar_nginx {
    echo "🌐 Configurando NGINX para proxy HTTPS local..."

    sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     $CERT_DIR/ghost.crt;
    ssl_certificate_key $CERT_DIR/ghost.key;

    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
    }

    location /media/ {
        alias $PROJECT_DIR/media/;
    }

    location /ghostrecon/ {
        proxy_pass http://0.0.0.0:$GUNICORN_PORT/ghostrecon/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    access_log $LOG_DIR/nginx_access.log;
    error_log  $LOG_DIR/nginx_error.log;
}

server {
    listen 80;
    return 301 https://\$host\$request_uri;
}
EOF

    sudo ln -sf "$NGINX_CONF" "$NGINX_LINK"
    sudo nginx -t && sudo systemctl restart nginx
}

function configurar_entorno_virtual {
    echo "🐍 Configurando entorno virtual..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install -r "$PROJECT_DIR/requirements.txt"
    python manage.py collectstatic --noinput
}

function iniciar_gunicorn {
    echo "🚀 Iniciando Gunicorn en 0.0.0.0:$GUNICORN_PORT..."
    source "$VENV_DIR/bin/activate"
    gunicorn $PROJECT_NAME.wsgi:application \
      --bind 0.0.0.0:$GUNICORN_PORT \
      --workers 3 \
      --daemon \
      --error-logfile "$LOG_DIR/gunicorn_error.log"

    echo "✅ Gunicorn ejecutándose en segundo plano"
}

# === EJECUCIÓN ===
mkdir -p "$LOG_DIR"

instalar_nginx_y_certificado
configurar_nginx
configurar_entorno_virtual
iniciar_gunicorn

echo "🎉 Configuración completa. Accede a: https://localhost/ghostrecon/dashboard/"
