#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


set -e
echo "⚙️ Configurando Gunicorn para dominio apih.coretransapi.com..." | tee -a $LOG_DEPLOY

# Rutas
PROJECT_NAME="api_bank_h2"
USER="markmur88"
VENV_PATH="/home/${USER}/Documentos/Entorno/envAPP"
PROJECT_DIR="/home/${USER}/Documentos/GitHub/${PROJECT_NAME}"
SOCK_FILE="${PROJECT_DIR}/servers/gunicorn/api.sock"
GUNICORN_DIR="${PROJECT_DIR}/servers/gunicorn"
SERVICE_DIR="/etc/systemd/system"
SUPERVISOR_CONF="${PROJECT_DIR}/servers/supervisor/conf.d/${PROJECT_NAME}.conf"

# 1. Crear archivo gunicorn.socket
echo "📦 Creando gunicorn.socket..." | tee -a $LOG_DEPLOY
cat > "${GUNICORN_DIR}/gunicorn.socket" <<EOF
[Unit]
Description=Gunicorn Socket for ${PROJECT_NAME}
PartOf=gunicorn.service

[Socket]
ListenStream=${SOCK_FILE}
SocketMode=0660
SocketUser=www-data
SocketGroup=www-data

[Install]
WantedBy=sockets.target
EOF

# 2. Crear archivo gunicorn.service
echo "📦 Creando gunicorn.service..." | tee -a $LOG_DEPLOY
cat > "${GUNICORN_DIR}/gunicorn.service" <<EOF
[Unit]
Description=Gunicorn Daemon for ${PROJECT_NAME}
Requires=gunicorn.socket
After=network.target

[Service]
User=${USER}
Group=www-data
WorkingDirectory=${PROJECT_DIR}
Environment="PATH=${VENV_PATH}/bin"
ExecStart=${VENV_PATH}/bin/gunicorn \\
          --access-logfile - \\
          --workers 3 \\
          --bind unix:${SOCK_FILE} \\
          config.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

# 3. Copiar servicios a systemd
echo "🔄 Copiando servicios a ${SERVICE_DIR}..." | tee -a $LOG_DEPLOY
sudo cp "${GUNICORN_DIR}/gunicorn."* "${SERVICE_DIR}/"

# 4. Recargar systemd y habilitar servicios
echo "🧠 Recargando systemd..." | tee -a $LOG_DEPLOY
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "🚀 Habilitando y lanzando Gunicorn vía socket..." | tee -a $LOG_DEPLOY
sudo systemctl enable --now gunicorn.socket
sudo systemctl start gunicorn.service

# 5. Validar socket
if sudo ss -ltn | grep -q "${SOCK_FILE}"; then
    echo "✅ Socket creado correctamente en ${SOCK_FILE}" | tee -a $LOG_DEPLOY
else
    echo "❌ Error: el socket no fue creado." >&2 | tee -a $LOG_DEPLOY
    exit 1
fi

# 6. Verificar configuración de Nginx
echo "🔍 Verificando configuración de Nginx..." | tee -a $LOG_DEPLOY
if sudo nginx -t; then
    echo "✅ nginx.conf válido. Reiniciando Nginx..." | tee -a $LOG_DEPLOY
    sudo systemctl restart nginx
else
    echo "❌ nginx.conf con errores. Revisa manualmente." >&2 | tee -a $LOG_DEPLOY
    exit 1
fi

# 7. Eliminar configuración previa de Supervisor (si existe)
if [[ -f "$SUPERVISOR_CONF" ]]; then
    echo "🧹 Eliminando antigua configuración de Supervisor para Gunicorn..." | tee -a $LOG_DEPLOY
    rm -f "$SUPERVISOR_CONF"
    if command -v supervisorctl &>/dev/null; then
        echo "🛑 Deteniendo proceso supervisado..." | tee -a $LOG_DEPLOY
        supervisorctl stop "${PROJECT_NAME}" || true
        supervisorctl reread
        supervisorctl update
    fi
fi

# 8. Confirmación final
echo "🎉 Gunicorn y Nginx configurados correctamente con systemd y socket UNIX." | tee -a $LOG_DEPLOY
echo "🌐 Visita: https://apih.coretransapi.com" | tee -a $LOG_DEPLOY
