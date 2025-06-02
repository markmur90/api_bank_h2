#!/bin/bash
set -euo pipefail

# ----------------------------------------
# Carga de configuración desde config.py
# ----------------------------------------
eval "$(
  python3 - <<'PYCODE'
import config
vars = [
  'PROJECT_NAME','PROJECT_NAME_SOCK','PROJECT_DIR','SCRIPTS_DIR','SERVERS_DIR',
  'GUNICORN_DIR','SUPERVISOR_PROGRAM','SUPERVISOR_CONF','OLD_SUPERVISOR_CONF',
  'VENV_DIR','LOG_DIR','CACHE_DIR','REPORT_DIR','SOCK_FILE','GUNICORN_LOG',
  'ERROR_LOG','CRON_LOG','RUNNER_LOG','RED_LOG','STARTUP_LOG',
  'NGINX_SITES_AVAILABLE','NGINX_SITES_ENABLED','NGINX_CONF',
  'CERT_DIR','SSL_CERT','SSL_KEY','TOR_CONFIG','APP_URL'
]
for v in vars:
    val = getattr(config, v)
    print(f'{v}=\"{val}\"')
PYCODE
)"

DIVIDER="========================================"
OP_LOG="$LOG_DIR/operation.log"

start_block(){
  echo -e "\n$DIVIDER\n>> INICIO: $1\n$DIVIDER" | tee -a "$OP_LOG"
}
end_block(){
  echo -e "$DIVIDER\n<< FIN:    $1\n$DIVIDER" | tee -a "$OP_LOG"
}

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$CACHE_DIR" "$GUNICORN_DIR"

# 1. Detener Servicios
stop_services(){
  start_block "Detener Servicios"
  sudo supervisorctl stop "$SUPERVISOR_PROGRAM" &>>"$OP_LOG" || echo "Supervisor no activo" | tee -a "$OP_LOG"
  pkill -f "gunicorn.*$PROJECT_NAME"    &>>"$OP_LOG" || echo "No procesos Gunicorn" | tee -a "$OP_LOG"
  [ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo "Socket eliminado" | tee -a "$OP_LOG"
  sudo systemctl stop nginx             &>>"$OP_LOG" || echo "Nginx no activo" | tee -a "$OP_LOG"
  end_block "Detener Servicios"
}

# 2. Limpiar Logs
clean_logs(){
  start_block "Limpiar Logs"
  truncate -s 0 "$ERROR_LOG" "$CRON_LOG" "$RUNNER_LOG" "$GUNICORN_LOG" 2>/dev/null
  echo "Logs truncados" | tee -a "$OP_LOG"
  end_block "Limpiar Logs"
}

# 3. Instalar Dependencias (incluye stem siempre)
install_dependencies(){
  start_block "Instalar Dependencias"
  source "$VENV_DIR/bin/activate"
  if [ -f "$PROJECT_DIR/requirements.txt" ]; then
    "$VENV_DIR/bin/pip" install -r "$PROJECT_DIR/requirements.txt" &>>"$OP_LOG" \
      && echo "Requisitos instalados" | tee -a "$OP_LOG"
  fi
  # Asegurar stem siempre
  "$VENV_DIR/bin/pip" install stem &>>"$OP_LOG" \
    && echo "Stem instalado" | tee -a "$OP_LOG"
  end_block "Instalar Dependencias"
}

# 4. Configurar Red/MAC-IP
network_setup(){
  start_block "Configurar Red/MAC-IP"
  IFACE=$(ip route get 8.8.8.8 | sed -n 's/.* dev \([^ ]*\) .*/\1/p')
  echo "Interfaz: $IFACE" | tee -a "$OP_LOG"
  [ -f "$CACHE_DIR/mac_actual.txt" ] && mv "$CACHE_DIR/mac_actual.txt" "$CACHE_DIR/mac_antes.txt"
  [ -f "$CACHE_DIR/ip_actual.txt" ] && mv "$CACHE_DIR/ip_actual.txt" "$CACHE_DIR/ip_antes.txt"
  PREV_MAC=$(cat "$CACHE_DIR/mac_antes.txt" 2>/dev/null || ip link show "$IFACE" | awk '/link\/ether/ {print $2}')
  PREV_IP=$(ip -4 addr show "$IFACE" | awk '/inet /{print $2}'|cut -d/ -f1)
  echo "Antes MAC:$PREV_MAC IP:$PREV_IP" | tee -a "$OP_LOG"
  sudo ip link set "$IFACE" down   &>>"$OP_LOG" || true
  { set +e; sudo macchanger -r "$IFACE" &>>"$OP_LOG"; set -e; } || echo "macchanger omitido" | tee -a "$OP_LOG"
  sudo ip link set "$IFACE" up     &>>"$OP_LOG" || true
  sudo dhclient -r "$IFACE"         &>>"$OP_LOG" || true
  sudo dhclient "$IFACE"            &>>"$OP_LOG" || true
  NEW_MAC=$(ip link show "$IFACE" | awk '/link\/ether/ {print $2}')
  NEW_IP=$(ip -4 addr show "$IFACE" | awk '/inet /{print $2}'|cut -d/ -f1)
  echo "Nueva MAC:$NEW_MAC IP:$NEW_IP" | tee -a "$OP_LOG"
  echo -e "$DIVIDER\n$(date '+%Y-%m-%d %H:%M:%S')\nMAC $PREV_MAC -> $NEW_MAC\nIP  $PREV_IP -> $NEW_IP" >>"$RED_LOG"
  end_block "Configurar Red/MAC-IP"
}

# 5. Configurar UFW
configure_ufw(){
  start_block "Configurar UFW"
  sudo ufw --force reset           &>>"$OP_LOG"
  sudo ufw default deny incoming   &>>"$OP_LOG"
  sudo ufw default allow outgoing  &>>"$OP_LOG"
  for p in 80 443 8000 8001 9050 9051; do sudo ufw allow "$p"/tcp &>>"$OP_LOG"; done
  sudo ufw --force enable          &>>"$OP_LOG"
  echo "UFW configurado" | tee -a "$OP_LOG"
  end_block "Configurar UFW"
}

# 6. Configurar Tor
configure_tor(){
  start_block "Configurar Tor"
  if [ -e /etc/tor/torrc ] || [ -L /etc/tor/torrc ]; then
    echo "Restableciendo /etc/tor/torrc" | tee -a "$OP_LOG"
    sudo rm -f /etc/tor/torrc
  fi
  echo "Copiando $TOR_CONFIG → /etc/tor/torrc" | tee -a "$OP_LOG"
  sudo cp "$TOR_CONFIG" /etc/tor/torrc
  sudo chown root:root /etc/tor/torrc
  sudo chmod 644        /etc/tor/torrc
  if pgrep tor &>/dev/null; then
    echo "Recargando Tor" | tee -a "$OP_LOG"
    sudo systemctl restart tor &>>"$OP_LOG"
  else
    echo "Iniciando Tor" | tee -a "$OP_LOG"
    sudo systemctl start tor &>>"$OP_LOG"
  fi
  end_block "Configurar Tor"
}

# 7. Configurar SSL
configure_ssl(){
  start_block "Configurar SSL"
  sudo mkdir -p "$CERT_DIR"
  if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "$SSL_KEY" -out "$SSL_CERT" \
      -subj "/C=DE/ST=Hessen/L=Frankfurt/O=GhostRecon/OU=Dev/CN=localhost" &>>"$OP_LOG"
    echo "Certificados generados" | tee -a "$OP_LOG"
  else
    echo "Certificados existentes" | tee -a "$OP_LOG"
  fi
  end_block "Configurar SSL"
}

# 8. Migraciones Django
run_migrations(){
  start_block "Migraciones Django"
  # find "$PROJECT_DIR/reconocimiento/migrations" -type f ! -name "__init__.py" -delete
  cd "$PROJECT_DIR"
  source "$VENV_DIR/bin/activate"
  python3 manage.py makemigrations 2>&1 | tee -a "$OP_LOG"
  python3 manage.py migrate       2>&1 | tee -a "$OP_LOG"
#   python3 manage.py createsuperuser 2>&1 | tee -a "$OP_LOG"
  end_block "Migraciones Django"
}

# 9. Configurar Supervisor
configure_supervisor(){
  start_block "Configurar Supervisor"
  sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:${SUPERVISOR_PROGRAM}]
directory=${PROJECT_DIR}
command=${VENV_DIR}/bin/gunicorn bank_ghost.wsgi:application --bind unix:${SOCK_FILE} --workers 3 --log-file ${GUNICORN_LOG} --error-logfile ${ERROR_LOG}
autostart=true
autorestart=true
stderr_logfile=${ERROR_LOG}
stdout_logfile=${GUNICORN_LOG}
user=${USER}
EOF
  end_block "Configurar Supervisor"
}

# 10. Configurar Nginx
configure_nginx(){
  start_block "Configurar Nginx"

  # 1) Eliminar cualquier configuración por defecto
  sudo rm -f /etc/nginx/sites-enabled/default
  sudo rm -f /etc/nginx/sites-enabled/default.conf
  sudo rm -f /etc/nginx/conf.d/default.conf

  # 2) Habilitar sólo bank_ghost
  sudo ln -sf "$NGINX_CONF" "$NGINX_SITES_ENABLED/${PROJECT_NAME}"

  # 3) Validar configuración
  sudo nginx -t &>>"$OP_LOG" || {
    echo "❌ Error en configuración Nginx, revisa $OP_LOG" | tee -a "$OP_LOG"
    exit 1
  }

  # 4) Si Nginx ya corre, recarga. Si no, arranca.
  if systemctl is-active --quiet nginx; then
    sudo systemctl reload nginx &>>"$OP_LOG"
    echo "✅ Nginx recargado" | tee -a "$OP_LOG"
  else
    sudo systemctl start nginx  &>>"$OP_LOG"
    echo "✅ Nginx iniciado"  | tee -a "$OP_LOG"
  fi

  end_block "Configurar Nginx"
}


# 11. Iniciar Gunicorn
start_gunicorn(){
  start_block "Iniciar Gunicorn"
  sudo supervisorctl reread  &>>"$OP_LOG"
  sudo supervisorctl update  &>>"$OP_LOG"
  sudo supervisorctl start "$SUPERVISOR_PROGRAM" &>>"$OP_LOG"
  for i in {1..10}; do
    [ -S "$SOCK_FILE" ] && break
    sleep 0.5
  done
  sudo chown "$USER":www-data "$SOCK_FILE"
  sudo chmod 660 "$SOCK_FILE"
  echo "Gunicorn activo" | tee -a "$OP_LOG"
  end_block "Iniciar Gunicorn"
}

# 12. Reconocimiento Manual
run_recon(){
  start_block "Ghost Recon Manual"
  python3 "$SCRIPTS_DIR/ghost_recon_ultimate.py" | tee -a "$OP_LOG"
  end_block "Ghost Recon Manual"
}

# 13. Abrir Interfaz
open_interface(){
  start_block "Abrir Interfaz"
  firefox --new-window "$APP_URL" &>/dev/null
  end_block "Abrir Interfaz"
}

# 14. Log de Arranque
log_startup(){
  echo -e "\n$DIVIDER\n$(date '+%Y-%m-%d %H:%M:%S') — Ghost Recon iniciado\n$DIVIDER" >>"$STARTUP_LOG"
}

# ---- Ejecución ----
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
