#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail



BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR" || exit 1

if [[ -f "$BASE_DIR/.env" ]]; then
  source "$BASE_DIR/.env"
else
  echo "❌ No se encontró el archivo .env"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"

INTERFAZ="${INTERFAZ:-eth0}"
if ! ip link show "$INTERFAZ" >/dev/null 2>&1; then
  echo "❌ Interfaz $INTERFAZ no válida o no detectada."
  exit 1
fi

get_ip_tor() {
  curl -s --socks5 127.0.0.1:9050 https://api.ipify.org || echo "Desconocida"
}

echo "🌐 Obteniendo IP de salida actual por Tor..."
IP_TOR_ANTES=$(get_ip_tor)
echo "$IP_TOR_ANTES" > "$CACHE_DIR/ip_tor_antes.txt"

echo "🛡️  Iniciando configuración avanzada de Tor..."
if ! command -v tor >/dev/null 2>&1; then
  echo "Tor no está instalado. Instalando..."
  sudo apt-get update && sudo apt-get install -y tor || {
    echo "Falló la instalación de Tor"
    exit 1
  }
fi

TORRC_PATH=""
TOR_PROC=$(pgrep -af tor | grep -v grep | head -n 1 || true)

if [[ -z "$TOR_PROC" ]]; then
  echo "No se encontró proceso Tor activo. Abortando."
  exit 1
fi

if echo "$TOR_PROC" | grep -q -- "-f"; then
  TORRC_PATH=$(echo "$TOR_PROC" | grep -oP '(?<=-f )\S+')
  echo "Tor usa archivo de configuración personalizado: $TORRC_PATH"
else
  TORRC_PATH="/etc/tor/torrc"
  echo "Tor usa archivo de configuración por defecto: $TORRC_PATH"
fi

sudo cp "$TORRC_PATH" "${TORRC_PATH}.bak_$(date +%Y%m%d_%H%M%S)"
echo "Backup de torrc creado."

TOR_PASS="${TOR_PASS:-Ptf8454Jd55}"
HASHED_PASS=$(tor --hash-password "$TOR_PASS" | tail -n 1)

replace_or_add_line() {
  local file="$1"
  local directive="$2"
  local value="$3"
  if sudo grep -q "^$directive" "$file"; then
    sudo sed -i "s|^$directive.*|$directive $value|" "$file"
  else
    echo "$directive $value" | sudo tee -a "$file" > /dev/null
  fi
}

replace_or_add_line "$TORRC_PATH" "ControlPort" "9051"
replace_or_add_line "$TORRC_PATH" "CookieAuthentication" "0"
replace_or_add_line "$TORRC_PATH" "HashedControlPassword" "$HASHED_PASS"

sudo systemctl enable tor
sudo systemctl restart tor || exit 1
sleep 3

echo "🔑 Autenticando con ControlPort..."
AUTH_CMD=$(printf 'AUTHENTICATE "%s"\r\nSIGNAL NEWNYM\r\nQUIT\r\n' "$TOR_PASS")
CHECK=$(echo -e "$AUTH_CMD" | nc 127.0.0.1 9051 || true)

if ! echo "$CHECK" | grep -q "250 OK"; then
  echo "❌ Error autenticando con Tor ControlPort:"
  echo "$CHECK" | tee -a "$LOG_SISTEMA"
  exit 1
fi

sleep 5
IP_TOR_DESPUES=$(get_ip_tor)
echo "$IP_TOR_DESPUES" > "$CACHE_DIR/ip_tor_despues.txt"

echo -e "\n\033[7;30m🔁 Cambiando MAC de la interfaz $INTERFAZ\033[0m" | tee -a "$LOG_SISTEMA"

sudo ip link set "$INTERFAZ" up
sleep 2

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
IP_ANTERIOR=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
echo "$MAC_ANTERIOR" > "$CACHE_DIR/mac_antes.txt"
echo "$IP_ANTERIOR"  > "$CACHE_DIR/ip_antes.txt"

sudo dhclient -r "$INTERFAZ" >> "$LOG_SISTEMA" 2>&1
sudo ip link set "$INTERFAZ" down

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
sudo ip link set "$INTERFAZ" up
sleep 2

renovar_ip() {
  local intento=$1
  sudo HOSTNAME="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)" dhclient -v "$INTERFAZ" >> "$LOG_SISTEMA" 2>&1
  sleep 4
  IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
  echo "$IP_ACTUAL" > "$CACHE_DIR/ip_actual.txt"
}

renovar_ip 1

if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
  echo "⚠ IP no ha cambiado tras el primer intento. Reintentando..." | tee -a "$LOG_SISTEMA"
  sudo ip link set "$INTERFAZ" down
  MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
  sudo ip link set "$INTERFAZ" up
  renovar_ip 2
fi

FECHA="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo ""
  echo "========================================="
  echo "📅 Fecha           : $FECHA"
  echo "🛰️ Interfaz        : $INTERFAZ"
  echo "🧭 MAC anterior    : $MAC_ANTERIOR"
  echo "✨ MAC actual      : $MAC_NUEVA"
  echo "🧭 IP anterior     : $IP_ANTERIOR"
  echo "🛰️ IP actual       : $IP_ACTUAL"
  echo "🧭 IP Tor anterior : $IP_TOR_ANTES"
  echo "🛰️ IP Tor actual   : $IP_TOR_DESPUES"
  echo "========================================="
} | tee -a "$LOG_SISTEMA"

echo "✔️ Cambios de red y anonimato completados con éxito."

