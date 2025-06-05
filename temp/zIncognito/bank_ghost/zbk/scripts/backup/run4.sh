#!/bin/bash
set -euo pipefail

eval "$(
  python3 - <<'PYCODE'
import config
vars = [
  'PROJECT_NAME','PROJECT_NAME_SOCK','PROJECT_DIR','SCRIPTS_DIR','SERVERS_DIR',
  'GUNICORN_DIR','SUPERVISOR_PROGRAM','SUPERVISOR_CONF','OLD_SUPERVISOR_CONF',
  'VENV_DIR','LOG_DIR','CACHE_DIR','REPORT_DIR','SOCK_FILE','GUNICORN_LOG',
  'ERROR_LOG','CRON_LOG','RUNNER_LOG','RED_LOG','STARTUP_LOG', 'PIDFILE',
  'NGINX_SITES_AVAILABLE','NGINX_SITES_ENABLED','NGINX_CONF', 'PORT',
  'CERT_DIR','SSL_CERT','SSL_KEY','TOR_CONFIG','APP_URL', 'TOR_PASS',
  'OPERATION_LOG',
]
for v in vars:
    val = getattr(config, v)
    print(f'{v}=\"{val}\"')
PYCODE
)"

DIVIDER="========================================"


start_block(){
  echo -e "\n$DIVIDER\n>> INICIO: $1\n$DIVIDER" | tee -a "$OPERATION_LOG"
}
end_block(){
  echo -e "$DIVIDER\n<< FIN:    $1\n$DIVIDER" | tee -a "$OPERATION_LOG"
}

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$CACHE_DIR" "$GUNICORN_DIR"

restart_gunicorn(){
  start_block "Reiniciar Gunicorn"
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
    rm -f "$PIDFILE"
    echo "🚧 Gunicorn detenido" | tee -a "$OPERATION_LOG"
  fi
  echo "♻️ Reiniciando Gunicorn en 0.0.0.0:$PORT" | tee -a "$OPERATION_LOG"
  gunicorn bank_ghost.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --workers 3 \
    --daemon \
    --pid "$PIDFILE" \
    --error-logfile "$GUNICORN_LOG" | tee -a "$OPERATION_LOG"
  end_block "Reiniciar Gunicorn"
}

if [ "${1:-}" == "restart" ]; then
  restart_gunicorn
  exit 0
fi

stop_services(){
  start_block "Detener Servicios"
  sudo supervisorctl stop "$SUPERVISOR_PROGRAM" &>>"$OPERATION_LOG" || echo "Supervisor no activo" | tee -a "$OPERATION_LOG"
  pkill -f "gunicorn.*$PROJECT_NAME" &>>"$OPERATION_LOG" || echo "No procesos Gunicorn" | tee -a "$OPERATION_LOG"
  [ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo "Socket eliminado" | tee -a "$OPERATION_LOG"
  sudo systemctl stop nginx &>>"$OPERATION_LOG" || echo "Nginx no activo" | tee -a "$OPERATION_LOG"
  end_block "Detener Servicios"
}

clean_logs(){
  start_block "Limpiar Logs"
  truncate -s 0 "$ERROR_LOG" "$CRON_LOG" "$RUNNER_LOG" "$GUNICORN_LOG" 2>/dev/null
  echo "Logs truncados" | tee -a "$OPERATION_LOG"
  end_block "Limpiar Logs"
}

install_dependencies(){
  start_block "Instalar Dependencias"
  sudo apt update &>>"$OPERATION_LOG"
  sudo apt install -y python3-venv python3-pip ufw tor macchanger curl &>>"$OPERATION_LOG"
  "$VENV_DIR/bin/pip" install -r "$PROJECT_DIR/requirements.txt" &>>"$OPERATION_LOG"
  end_block "Instalar Dependencias"
}

network_setup(){
  start_block "Configurar Red/MAC-IP"
  IFACE=$(ip route get 8.8.8.8 | sed -n 's/.* dev \([^ ]*\) .*/\1/p')
  echo "Interfaz: $IFACE" | tee -a "$OPERATION_LOG"
  [ -f "$CACHE_DIR/mac_actual.txt" ] && mv "$CACHE_DIR/mac_actual.txt" "$CACHE_DIR/mac_antes.txt"
  [ -f "$CACHE_DIR/ip_actual.txt" ] && mv "$CACHE_DIR/ip_actual.txt" "$CACHE_DIR/ip_antes.txt"
  PREV_MAC=$(cat "$CACHE_DIR/mac_antes.txt" 2>/dev/null || ip link show "$IFACE" | awk '/link\/ether/ {print $2}')
  PREV_IP=$(ip -4 addr show "$IFACE" | awk '/inet /{print $2}'|cut -d/ -f1)
  echo "Antes MAC:$PREV_MAC IP:$PREV_IP" | tee -a "$OPERATION_LOG"
  sudo ip link set "$IFACE" down &>>"$OPERATION_LOG" || true
  { set +e; sudo macchanger -r "$IFACE" &>>"$OPERATION_LOG"; set -e; } || echo "macchanger omitido" | tee -a "$OPERATION_LOG"
  sudo ip link set "$IFACE" up &>>"$OPERATION_LOG" || true
  sudo dhclient -r "$IFACE" &>>"$OPERATION_LOG" || true
  sudo dhclient "$IFACE" &>>"$OPERATION_LOG" || true
  NEW_MAC=$(ip link show "$IFACE" | awk '/link\/ether/ {print $2}')
  NEW_IP=$(ip -4 addr show "$IFACE" | awk '/inet /{print $2}'|cut -d/ -f1)
  echo "Nueva MAC:$NEW_MAC IP:$NEW_IP" | tee -a "$OPERATION_LOG"
  echo -e "$DIVIDER\n$(date '+%Y-%m-%d %H:%M:%S')\nMAC $PREV_MAC -> $NEW_MAC\nIP  $PREV_IP -> $NEW_IP" >>"$RED_LOG"
  end_block "Configurar Red/MAC-IP"
}

configure_ufw(){
  start_block "Configurar UFW"
  sudo ufw --force reset &>>"$OPERATION_LOG"
  sudo ufw default deny incoming &>>"$OPERATION_LOG"
  sudo ufw default allow outgoing &>>"$OPERATION_LOG"
  for p in 80 443 2222 8000 8001 8011 9050 9051; do sudo ufw allow "$p"/tcp &>>"$OPERATION_LOG"; done
  sudo ufw --force enable &>>"$OPERATION_LOG"
  echo "UFW configurado" | tee -a "$OPERATION_LOG"
  end_block "Configurar UFW"
}

configure_tor(){
  start_block "Configurar Tor"
  sudo grep -q '^ControlPort' "$TOR_CONFIG" || echo 'ControlPort 9051' | sudo tee -a "$TOR_CONFIG"
  sudo grep -q '^CookieAuthentication' "$TOR_CONFIG" || echo 'CookieAuthentication 0' | sudo tee -a "$TOR_CONFIG"
  if ! pgrep tor > /dev/null; then
    sudo systemctl restart tor |& tee -a "$OPERATION_LOG" || {
      sudo apt install -y tor &>>"$OPERATION_LOG"
      sudo systemctl enable tor
      sudo systemctl start tor
    }
  fi
  CHECK=$(echo -e "AUTHENTICATE \"$TOR_PASS\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc 127.0.0.1 9051)
  if echo "$CHECK" | grep -q "250 OK"; then
    echo "Tor listo: $CHECK" | tee -a "$OPERATION_LOG"
  else
    echo "Error Tor: $CHECK" | tee -a "$OPERATION_LOG"
  fi
  end_block "Configurar Tor"
}

configure_ssl(){
  start_block "Configurar SSL"
  sudo mkdir -p "$(dirname "$SSL_CERT")"
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/CN=$(hostname)" \
    -keyout "$SSL_KEY" -out "$SSL_CERT" &>>"$OPERATION_LOG"
  end_block "Configurar SSL"
}

run_migrations(){
  start_block "Migraciones"
  cd "$PROJECT_DIR"
  "$VENV_DIR/bin/python" manage.py migrate &>>"$OPERATION_LOG"
  end_block "Migraciones"
}

configure_supervisor(){
  start_block "Configurar Supervisor"
  sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:$SUPERVISOR_PROGRAM]
directory=$PROJECT_DIR
command=${VENV_DIR}/bin/gunicorn bank_ghost.wsgi:application --bind unix:$SOCK_FILE --workers 3 --log-file ${GUNICORN_LOG} --error-logfile ${ERROR_LOG}
autostart=true
autorestart=true
stderr_logfile=${ERROR_LOG}
stdout_logfile=${GUNICORN_LOG}
user=${USER}
EOF
  sudo supervisorctl reread &>>"$OPERATION_LOG"
  sudo supervisorctl update &>>"$OPERATION_LOG"
  end_block "Configurar Supervisor"
}

configure_nginx(){
  start_block "Configurar Nginx"
  sudo rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.conf /etc/nginx/conf.d/default.conf
  sudo ln -sf "$NGINX_CONF" "$NGINX_SITES_ENABLED/$PROJECT_NAME"
  if sudo nginx -t &>>"$OPERATION_LOG"; then
    sudo systemctl reload nginx &>>"$OPERATION_LOG"
  else
    sudo systemctl start nginx &>>"$OPERATION_LOG"
  fi
  end_block "Configurar Nginx"
}

start_gunicorn(){
  start_block "Iniciar Gunicorn"
  echo "🚀 Iniciando Gunicorn en 0.0.0.0:$PORT" | tee -a "$OPERATION_LOG"
  gunicorn bank_ghost.wsgi:application \
    --bind 0.0.0.0:$PORT \
    --workers 3 \
    --daemon \
    --pid "$PIDFILE" \
    --error-logfile "$GUNICORN_LOG" | tee -a "$OPERATION_LOG"
  end_block "Iniciar Gunicorn"
}

run_recon(){
  start_block "Ghost Recon"
  "$SCRIPTS_DIR/x05.sh"
  end_block "Ghost Recon"
}

open_interface(){
  start_block "Abrir Interfaz"
  firefox --new-window "$APP_URL" &>/dev/null
  end_block "Abrir Interfaz"
}

log_startup(){
  echo -e "\n$DIVIDER\n$(date '+%Y-%m-%d %H:%M:%S') — Ghost Recon iniciado\n$DIVIDER" >>"$STARTUP_LOG"
}

stop_services
clean_logs
install_dependencies
network_setup
configure_ufw
configure_tor
configure_ssl
run_migrations
configure_supervisor
configure_nginx
start_gunicorn
[ "${1:-}" == "recon" ] && run_recon
open_interface
log_startup
