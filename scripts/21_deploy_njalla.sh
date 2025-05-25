#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./logs/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

if [[ "$1" != "production" ]]; then
  echo "⚠️ Este script sólo debe ejecutarse en entorno de producción. Abortando."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

VPS_USER="${VPS_USER:-markmur88}"
VPS_IP="${VPS_IP:-80.78.30.188}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
APP_DIR="${VPS_API_DIR:-/home/$VPS_USER/api_bank}"


log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_DEPLOY"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_DEPLOY"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_DEPLOY"; }

log_info "🚀 Sincronizando proyecto api_bank_h2 al VPS ($VPS_IP)..."

rsync -avz -e "ssh -i $SSH_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$HOME/.ssh/known_hosts" \
  "$PROJECT_ROOT/" "$VPS_USER@$VPS_IP:$APP_DIR" >> "$LOG_DEPLOY" 2>&1

log_ok "📦 Proyecto sincronizado en VPS: $APP_DIR"

log_info "⚙️ Configurando entorno en VPS..."

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=yes -o UserKnownHostsFile="$HOME/.ssh/known_hosts" "$VPS_USER@$VPS_IP" bash <<EOF
set -e

sudo apt update
sudo apt install -y python3-pip python3-venv nginx certbot python3-certbot-nginx supervisor

cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Crear directorios de logs si no existen
mkdir -p logs

# Crear/actualizar service y socket systemd para gunicorn
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOL
[Unit]
Description=Gunicorn daemon for api_bank_h2
Requires=gunicorn.socket
After=network.target

[Service]
User=$VPS_USER
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=$APP_DIR/venv/bin/gunicorn --access-logfile - --workers 3 --bind unix:/run/gunicorn.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
EOL

sudo tee /etc/systemd/system/gunicorn.socket > /dev/null <<EOL
[Unit]
Description=Gunicorn socket for api_bank_h2
PartOf=gunicorn.service

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now gunicorn.socket

# Configurar nginx
sudo tee /etc/nginx/sites-available/api_bank_h2 > /dev/null <<EOL
upstream coretransapi {
    server unix:/run/gunicorn.sock;
}

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

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://coretransapi;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
    }

    access_log $APP_DIR/logs/nginx_access.log combined;
    error_log $APP_DIR/logs/nginx_error.log;
}
EOL

sudo ln -sf /etc/nginx/sites-available/api_bank_h2 /etc/nginx/sites-enabled/api_bank_h2

sudo nginx -t
sudo systemctl reload nginx || sudo systemctl start nginx

log_ok "✅ Configuración nginx recargada"

# Certbot para SSL (solo si no existe certificado)
if [ ! -d "/etc/letsencrypt/live/api.coretransapi.com" ]; then
  sudo certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m tu-email@dominio.com
fi

log_ok "✅ Certificado SSL configurado"

EOF

log_ok "✅ Despliegue y configuración en VPS completados."
