#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURACIÓN ===
PUERTOS=(8000 5000 35729)
URL_LOCAL="http://localhost:5000"
URL_GUNICORN="gunicorn config.wsgi:application --bind 127.0.0.1:8000"
URL_HEROKU="https://apibank2-d42d7ed0d036.herokuapp.com/"
URL_NJALLA="https://api.coretransapi.com/"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

# === FUNCIONES ===
liberar_puertos() {
    for port in "${PUERTOS[@]}"; do
        if lsof -i :$port &>/dev/null; then
            echo -e "\033[1;34m🔌 Liberando puerto $port...\033[0m"
            kill $(lsof -t -i :$port) &>/dev/null || true
        fi
    done
}

limpiar_y_salir() {
    echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m"
    pkill -f "gunicorn" &>/dev/null || true
    pkill -f "honeypot.py" &>/dev/null || true
    pkill -f "livereload" &>/dev/null || true
    [ -n "${FIREFOX_PID:-}" ] && kill "$FIREFOX_PID" 2>/dev/null || true
    liberar_puertos
    echo -e "\033[1;32m✅ Todos los servicios detenidos.\033[0m"
    echo -e "$LOGO_SEP\n"
    exit 0
}

iniciar_entorno() {
    echo -e "\033[1;36m📦 Activando entorno virtual y configuración...\033[0m"
    cd "$PROJECT_ROOT"
    source "$VENV_PATH/bin/activate"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@localhost:5432/mydatabase"
    python manage.py collectstatic --noinput
}

verificar_seguridad() {
    if [[ "$ENVIRONMENT" != "local" ]]; then
        echo -e "\033[1;31m🔒 Verificando conexión segura: VPN + Tor...\033[0m"
        if ! curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org | grep -q "Congratulations"; then
            echo -e "\033[1;31m❌ Error: No estás conectado por Tor. Abortando por seguridad.\033[0m"
            exit 1
        fi
        echo -e "\033[1;32m✅ Tor activo. Entorno seguro.\033[0m"
    fi
}



# === INICIO GUNICORN + HONEYPOT ===
echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m"
trap limpiar_y_salir SIGINT
verificar_seguridad
liberar_puertos
iniciar_entorno

echo -e "\n🔧 Configurando Gunicorn con systemd...\n"
{
    bash "${SCRIPTS_DIR}/configurar_gunicorn.sh"
    echo -e "✅ Gunicorn configurado correctamente.\n"
} >> "$STARTUP_LOG" 2>&1 || {
    echo -e "\033[1;31m❌ Error al configurar Gunicorn. Consulta $STARTUP_LOG\033[0m"
    exit 1
}

echo -e "\033[1;34m🌀 Lanzando servicios secundarios...\033[0m"
nohup python honeypot.py > "$LOG_DIR/honeypot.log" 2>&1 < /dev/null &
nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOG_DIR/livereload.log" 2>&1 < /dev/null &

sleep 1
firefox --new-window "$URL_LOCAL" --new-tab "$URL_GUNICORN" --new-tab "$URL_NJALLA" --new-tab "$URL_HEROKU" &
FIREFOX_PID=$!

echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m"
echo -e "$LOGO_SEP\n"
while true; do sleep 1; done