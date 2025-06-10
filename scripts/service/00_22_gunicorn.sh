#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$SCRIPTS_DIR/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail


LOG_DEPLOY="$SCRIPTS_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


# === VARIABLES BASE ===
LOG_DIR="$SCRIPTS_DIR/logs"
CACHE_DIR="$BASE_DIR/tmp"
nohup STARTUP_LOG="$LOG_DIR/startup_gunicorn.log" > logs/gunicorn_default.log 2>&1 &

mkdir -p "$LOG_DIR" "$CACHE_DIR"

# === CONFIGURACIÓN ===
PUERTOS=(8000 5000 35729)
URL_SSL_LOCAL="https://0.0.0.0:8443"
URL_GUNICORN="http://127.0.0.1:8000"
URL_HEROKU="https://apibank2-54644cdf263f.herokuapp.com/"
URL_NJALLA="https://api.coretransapi.com/"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

# === FUNCIONES ===

liberar_puertos() {
    for port in "${PUERTOS[@]}"; do
        if lsof -i :$port &>/dev/null; then
            echo -e "\033[1;34m🔌 Liberando puerto $port...\033[0m" | tee -a $LOG_DEPLOY
            sudo fuser -k "$port"/tcp || true
        fi
    done
}

limpiar_y_salir() {
    echo -e "\n\033[1;33m🧹 Deteniendo todos los servicios...\033[0m" | tee -a $LOG_DEPLOY
nohup pkill -f "gunicorn" &>/dev/null || true > logs/gunicorn_default.log 2>&1 &
    pkill -f "honeypot.py" &>/dev/null || true
    pkill -f "livereload" &>/dev/null || true
    [ -n "${FIREFOX_PID:-}" ] && kill "$FIREFOX_PID" 2>/dev/null || true
    liberar_puertos
    echo -e "\033[1;32m✅ Todos los servicios detenidos.\033[0m" | tee -a $LOG_DEPLOY
    echo -e "$LOGO_SEP\n" | tee -a $LOG_DEPLOY
    exit 0
}

iniciar_entorno() {
    echo -e "\033[1;36m📦 Activando entorno virtual y configuración...\033[0m" | tee -a $LOG_DEPLOY
    cd "$BASE_DIR"
    source "$VENV_PATH/bin/activate"
    export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"
    python manage.py collectstatic --noinput
}

verificar_seguridad() {
    if [[ "${ENVIRONMENT:-local}" != "local" ]]; then
        echo -e "\033[1;31m🔒 Verificando conexión segura: VPN + Tor...\033[0m" | tee -a $LOG_DEPLOY
        if ! curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org | grep -q "Congratulations"; then
            echo -e "\033[1;31m❌ Error: No estás conectado por Tor. Abortando por seguridad.\033[0m" | tee -a $LOG_DEPLOY
            exit 1
        fi
        echo -e "\033[1;32m✅ Tor activo. Entorno seguro.\033[0m" | tee -a $LOG_DEPLOY
    fi
}

# === EJECUCIÓN PRINCIPAL ===

echo -e "\033[7;30m🚀 Iniciando Gunicorn, honeypot y livereload...\033[0m" | tee -a $LOG_DEPLOY
trap limpiar_y_salir SIGINT

verificar_seguridad
liberar_puertos
iniciar_entorno

echo -e "\n🔧 Configurando Gunicorn con systemd...\n" | tee -a $LOG_DEPLOY
{
nohup bash "${SCRIPTS_DIR}/configurar_gunicorn.sh" > logs/gunicorn_default.log 2>&1 &
    echo -e "✅ Gunicorn configurado correctamente.\n" | tee -a $LOG_DEPLOY
} >> "$STARTUP_LOG" 2>&1 || {
    echo -e "\033[1;31m❌ Error al configurar Gunicorn. Consulta $STARTUP_LOG\033[0m" | tee -a $LOG_DEPLOY
    exit 1
}

echo -e "\033[1;34m🌀 Lanzando servicios secundarios...\033[0m" | tee -a $LOG_DEPLOY
nohup python honeypot.py > "$LOG_DIR/honeypot.log" 2>&1 < /dev/null &
nohup livereload --host 127.0.0.1 --port 35729 static/ -t templates/ > "$LOG_DIR/livereload.log" 2>&1 < /dev/null &

sleep 1

firefox --new-window "$URL_SSL_LOCAL" \
  --new-tab "$URL_GUNICORN" \
  --new-tab "$URL_NJALLA" \
  --new-tab "$URL_HEROKU" &
FIREFOX_PID=$!

echo -e "\033[7;30m🚧 Servicios activos. Ctrl+C para detener.\033[0m" | tee -a $LOG_DEPLOY
echo -e "$LOGO_SEP\n" | tee -a $LOG_DEPLOY
while true; do sleep 1; done