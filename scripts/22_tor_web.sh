#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Verificación de navegación vía Tor
# ===========================

# Cargar entorno desde .env
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

URL_HEROKU="https://${PROJECT_NAME}.herokuapp.com"

# Preparar log
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/master_run.log"
LOGO_SEP="\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

# Verificar si Tor está funcionando correctamente
log_info "🔎 Comprobando conexión a través de Tor..."

if curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/ 2>/dev/null | grep -q "Congratulations"; then
  log_ok "✅ Tor está funcionando correctamente"
else
  log_error "❌ No se detectó conexión Tor funcional"
  exit 1
fi

# Abrir web de Heroku con Firefox
log_info "🌐 Abriendo $URL_HEROKU a través de Firefox..."

FIREFOX_PID=""
firefox --new-window "$URL_HEROKU" & FIREFOX_PID=$!

echo -e "\033[7;30m🚧 Web abierta. Pulsa Ctrl+C para cerrar.\033[0m"
echo -e "$LOGO_SEP\n"

# Mantener proceso activo hasta interrupción
trap 'kill "$FIREFOX_PID" 2>/dev/null || true; echo -e "\n🧹 Firefox cerrado."; exit 0' SIGINT

while true; do sleep 3; done

