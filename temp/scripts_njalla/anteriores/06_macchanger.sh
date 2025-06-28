#!/usr/bin/env bash
set -euo pipefail

# ===========================
# Cambio de MAC + renovación IP
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

# Preparar logs
mkdir -p "$LOG_DIR" "$CACHE_DIR"
LOG_FILE="$LOG_DIR/master_run.log"
RED_LOG="$LOG_DIR/red.log"

log_info()  { echo -e "\033[1;34m[INFO] $1\033[0m" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "\033[1;32m[OK]   $1\033[0m" | tee -a "$LOG_FILE"; }
log_error() { echo -e "\033[1;31m[ERR]  $1\033[0m" | tee -a "$LOG_FILE"; }

renovar_ip() {
    local intento=$1
    local rand_host="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)"
    echo "📥 Intento $intento: solicitando nueva IP con hostname $rand_host..." | tee -a "$RED_LOG"
    sudo HOSTNAME="$rand_host" dhclient -v "$INTERFAZ" >> "$RED_LOG" 2>&1
    sleep 5
    ip addr show "$INTERFAZ" >> "$RED_LOG"
    IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
    IP_ACTUAL=${IP_ACTUAL:-"No disponible"}
    echo "$IP_ACTUAL" > "$CACHE_DIR/ip_actual.txt"
}

echo -e "\033[7;33m---------------------------------------------CAMBIO MAC--------------------------------------------\033[0m" | tee -a "$RED_LOG"
echo -e "\n\033[7;30m🔁 Cambiando MAC de la interfaz $INTERFAZ\033[0m" | tee -a "$RED_LOG"

sudo ip link set "$INTERFAZ" up
sleep 2

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}' || echo "No disponible")
IP_ANTERIOR=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
IP_ANTERIOR=${IP_ANTERIOR:-"No disponible"}

echo "$MAC_ANTERIOR" > "$CACHE_DIR/mac_antes.txt"
echo "$IP_ANTERIOR"  > "$CACHE_DIR/ip_antes.txt"

echo "📤 Liberando IP actual..." | tee -a "$RED_LOG"
sudo dhclient -r "$INTERFAZ" >> "$RED_LOG" 2>&1
sudo ip link set "$INTERFAZ" down

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
sudo ip link set "$INTERFAZ" up
sleep 2

renovar_ip 1

if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
    echo "⚠ IP no ha cambiado tras el primer intento. Reintentando..." | tee -a "$RED_LOG"
    sudo ip link set "$INTERFAZ" down
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    sleep 2
    renovar_ip 2

    if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
        echo "⚠️ La IP no cambió tras dos intentos. Posible rastreo por DHCP persistente." | tee -a "$RED_LOG"
    fi
fi

FECHA="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo "========================================="
  echo "🔁 Cambio de red realizado ($FECHA)"
  echo "🖧 Interfaz: $INTERFAZ"
  echo "🔍 MAC anterior: $MAC_ANTERIOR"
  echo "🎉 MAC actual:   $MAC_NUEVA"
  echo "🌐 IP anterior:  $IP_ANTERIOR"
  echo "🌐 IP actual:    $IP_ACTUAL"
  echo "========================================="
} | tee -a "$RED_LOG"

log_ok "✅ Cambio de MAC e IP completado con éxito."

