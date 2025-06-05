#!/bin/bash

set -e

PROJECT_NAME="bank_ghost"
PROJECT_NAME_SOCK="ghost"
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
# PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${PROJECT_DIR}/venv"

SERVERS_DIR="${PROJECT_DIR}/servers"
SD_GUN="${SERVERS_DIR}/gunicorn"
SD_NGI="${SERVERS_DIR}/nginx/sites-available"
SD_SUP="${SERVERS_DIR}/supervisor/conf.d"

SOCK_DIR="${SD_GUN}"
SOCK_FILE="${SOCK_DIR}/ghost.sock"
GUNICORN_LOG="${SOCK_DIR}/gunicorn.log"

LOG_DIR="${PROJECT_DIR}/logs"
ERROR_LOG="${LOG_DIR}/error.log"

SUPERVISOR_CONF="${SD_SUP}/${PROJECT_NAME}.conf"


NGINX_CONF="${SD_NGI}/${PROJECT_NAME}"
USER="markmur88"

echo "🚀 Iniciando configuración completa de $PROJECT_NAME..."

# Verificar que el script no necesita ser root excepto donde se indique
if [ "$EUID" -eq 0 ]; then
    echo "⚠️ No se recomienda ejecutar todo este script como root."
fi

# Crear usuario si no existe (requiere sudo)
# if ! id "$USER" &>/dev/null; then
#     echo "👤 Creando usuario $USER... (requiere privilegios)"
#     if command -v sudo &>/dev/null; then
#         sudo useradd -m -s /bin/bash "$USER"
#     else
#         echo "❌ 'sudo' no está disponible. No se puede crear el usuario."
#         exit 1
#     fi
# fi

# Crear entorno virtual si no existe
# if [ ! -d "$VENV_DIR" ]; then
#     echo "🐍 Creando entorno virtual..."
#     python3 -m venv "$VENV_DIR"
# fi

# Activar entorno virtual
if [ -f "$VENV_DIR/bin/activate" ]; then
    echo "✅ Activando entorno virtual..."
    source "$VENV_DIR/bin/activate"
else
    echo "❌ No se encontró el script de activación del entorno virtual."
    exit 1
fi

# Instalar requerimientos si el archivo existe
REQ_FILE="$PROJECT_DIR/requirements.txt"
if [ -f "$REQ_FILE" ]; then
    echo "📦 Instalando dependencias desde $REQ_FILE..."
    pip install --upgrade pip
    pip install -r "$REQ_FILE"
else
    echo "⚠️ No se encontró requirements.txt en $PROJECT_DIR."
fi

# Crear carpeta de logs si no existe
# mkdir -p "$LOG_DIR"

# Preparar supervisord config (requiere sudo)
if [ ! -f "$SUPERVISOR_CONF" ]; then
    echo "📄 Creando configuración de Supervisor..."
    if command -v sudo &>/dev/null; then
        sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:${PROJECT_NAME}]
directory=${PROJECT_DIR}
command=${VENV_DIR}/bin/gunicorn ${PROJECT_NAME}.wsgi:application --bind unix:${SOCK_FILE}
autostart=true
autorestart=true
stderr_logfile=${ERROR_LOG}
stdout_logfile=${GUNICORN_LOG}
user=${USER}
EOF
    else
        echo "❌ No se puede escribir en /etc sin sudo. Skipping..."
    fi
else
    echo "ℹ️ Configuración de Supervisor ya existe, no se sobrescribe."
fi

# Preparar configuración de Nginx (requiere sudo)
if [ ! -f "$NGINX_CONF" ]; then
    echo "🌐 Creando configuración de Nginx..."
    if command -v sudo &>/dev/null; then
        sudo tee "$NGINX_CONF" > /dev/null <<EOF
# AUTO-GENERATED NGINX CONF WITH SELF-SIGNED CERT
server {
    listen 80;
    server_name localhost;

    location / {
        include proxy_params;
        proxy_pass http://unix:${SOCK_FILE};
    }

    access_log ${LOG_DIR}/nginx_access.log;
    error_log ${LOG_DIR}/nginx_error.log;
}
EOF
        sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/"
    else
        echo "❌ No se puede configurar nginx sin sudo. Skipping..."
    fi
else
    echo "ℹ️ Configuración de Nginx ya existe, no se sobrescribe."
fi

echo "🎉 Script completado. Revisa los mensajes anteriores para acciones manuales pendientes."


# =========================== x01 ===========================