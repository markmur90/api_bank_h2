#!/usr/bin/env bash
BASE="$HOME/local"
CONF="$BASE/config"
LOG="$BASE/logs"
TMP_CONF="$CONF/nginx.conf"
TEMPLATE="$CONF/nginx.conf.template"

function find_free_port() {
  port=$1
  while lsof -i :"$port" &>/dev/null; do
    port=$((port+1))
  done
  echo $port
}

function kill_port() {
  pids=$(lsof -ti tcp:"$1")
  if [ -n "$pids" ]; then
    kill $pids
  fi
}

case "$1" in
  start)
    DJ_PORT=$(find_free_port 8001)
    kill_port 8000
    kill_port "$DJ_PORT"

    sleep 3
    echo ""
    echo "=== Iniciando Django en puerto $DJ_PORT ==="
    cd "$HOME/api_bank_h2" && pip3 install -r requirements.txt && python manage.py makemigrations && python manage.py migrate && python manage.py collectstatic --noinput && python manage.py runserver 0.0.0.0:$DJ_PORT >> "$LOG/service.log" 2>&1 &

    sleep 3
    echo ""
    echo "=== Configurando y arrancando Nginx ==="
    sed "s/{{DJANGO_PORT}}/$DJ_PORT/" "$TEMPLATE" > "$TMP_CONF"
    nginx -c "$TMP_CONF" >> "$LOG/nginx.log" 2>&1 &

    sleep 3
    echo ""
    echo "=== Iniciando Tor ==="
    # Genera torrc dinámico
    sed "s|\$HOME|$HOME|g" "$CONF/torrc.template" > "$CONF/torrc"
    tor -f "$CONF/torrc" >> "$LOG/tor.log" 2>&1 &

    sleep 3
    echo ""
    echo "=== Iniciando Ngrok ==="
    ngrok start --all --config="$CONF/ngrok.yml" >> "$LOG/ngrok.log" 2>&1 &
    sleep 3
    echo ""
    echo "Todos los servicios arrancados."
    ;;
  status)
    sleep 3
    echo ""
    echo "=== Puertos en uso ==="
    lsof -i TCP:8000 -sTCP:LISTEN
    lsof -i TCP:$(find_free_port 8001)
    ;;
  stop)
    sleep 3
    echo ""
    echo "=== Deteniendo servicios en 8000 y puertos dinámicos ==="
    kill_port 8000
    for p in $(lsof -ti tcp:8001-8100); do kill "$p"; done
    echo "Servicios detenidos."
    ;;
  *)
    echo "Uso: $0 {start|status|stop}"
    ;;
esac
