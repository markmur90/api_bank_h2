#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"
OPERATION_LOG="$LOG_DIR/operation.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

for var in SOCK_FILE SUPERVISOR_CONF SUPERVISOR_PROGRAM GUNICORN_LOG ERROR_LOG NGINX_CONF NGINX_SITES_ENABLED PROJECT_ROOT VENV_DIR USER SSL_KEY SSL_CERT; do
  if [[ -z "${!var-}" ]]; then
    log_error "Variable obligatoria $var no está definida. Abortando."
    exit 1
  fi
done

log_info "🔐 Generando certificado SSL autofirmado..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -subj "/CN=$(hostname)" \
  -keyout "$SSL_KEY" -out "$SSL_CERT" &>>"$OPERATION_LOG"

log_ok "✅ Certificado generado en $SSL_CERT"

log_info "🛠️ Configurando Supervisor para Gunicorn y levantando Gunicorn..."

if [ -S "$SOCK_FILE" ]; then
  rm -f "$SOCK_FILE"
  log_info "🗑️ Socket $SOCK_FILE eliminado previo"
fi

cd "$PROJECT_ROOT"
source "$VENV_DIR/bin/activate"

log_info "🔥 Iniciando Gunicorn para api_bank_heroku con bind a socket $SOCK_FILE..."
nohup "$VENV_DIR/bin/gunicorn" config.wsgi:application --chdir "$PROJECT_ROOT" --bind "unix:$SOCK_FILE" --workers 3 --log-file "$GUNICORN_LOG" --error-logfile "$ERROR_LOG" &> "$LOG_DIR/gunicorn_api_bank_heroku.log" &

sleep 3

if [ -S "$SOCK_FILE" ]; then
  log_ok "✅ Socket creado en $SOCK_FILE"
  chown "$(whoami)":www-data "$SOCK_FILE"
  chmod 660 "$SOCK_FILE"
  ls -l "$SOCK_FILE" | tee -a "$LOG_FILE"
else
  log_error "❌ No se pudo crear el socket en $SOCK_FILE. Revisa $ERROR_LOG"
  exit 2
fi

log_info "📋 Escribiendo configuración Supervisor..."
sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:$SUPERVISOR_PROGRAM]
directory=$PROJECT_ROOT
command=$VENV_DIR/bin/gunicorn config.wsgi:application --bind unix:$SOCK_FILE --workers 3 --log-file $GUNICORN_LOG --error-logfile $ERROR_LOG
autostart=true
autorestart=true
stderr_logfile=$ERROR_LOG
stdout_logfile=$GUNICORN_LOG
user=$USER
EOF

sudo supervisorctl reread &>>"$OPERATION_LOG"
sudo supervisorctl update &>>"$OPERATION_LOG"
log_ok "✅ Configuración de Supervisor actualizada"

log_info "🌐 Enlazando configuración de Nginx..."

sudo rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.conf /etc/nginx/conf.d/default.conf
sudo ln -sf "$NGINX_CONF" "$NGINX_SITES_ENABLED/$PROJECT_NAME"

if sudo nginx -t &>>"$OPERATION_LOG"; then
  sudo systemctl reload nginx || sudo systemctl start nginx
  log_ok "✅ Nginx configurado y recargado correctamente"
else
  log_error "❌ Error en la configuración de Nginx. Verifica $OPERATION_LOG"
  exit 1
fi
