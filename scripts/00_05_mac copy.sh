#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
LOG_DIR="$PROJECT_ROOT/logs"
INTERFAZ=wlan0
CACHE_DIR="$PROJECT_ROOT/tmp"
mkdir -p "$CACHE_DIR"

IP_ANT="$CACHE_DIR/ip_antes.txt"
IP_ACT="$CACHE_DIR/ip_actual.txt"
MC_ANT="$CACHE_DIR/mac_antes.txt"
MC_ACT="$CACHE_DIR/mac_actual.txt"

# === FUNCIONES ===

verificar_tor_activo() {
    if ! pgrep tor &>/dev/null; then
        echo -e "\033[7;31m❌ El servicio Tor no está activo. Iniciando...\033[0m"
        sudo systemctl start tor
        sleep 3
    fi
    if curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org | grep -q "Congratulations"; then
        echo -e "\033[7;32m🧅 Tor activo y operativo. Conectado a la red Tor.\033[0m"
    else
        echo -e "\033[7;31m❌ No se pudo verificar la conexión por Tor. Abortando.\033[0m"
        exit 1
    fi
}

ver_ip_publica_tor() {
    local ip=$(curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org || echo "N/D")
    echo "$ip"
}

# === EJECUCIÓN ===

echo -e "\033[7;30m🔒 Verificando conexión Tor...\033[0m"
verificar_tor_activo

# === GUARDAR Y MOSTRAR IP TOR ===
echo -e "\033[7;30m🌐 Consultando IP pública vía Tor...\033[0m"
IP_PUBLICA=$(ver_ip_publica_tor)
echo "$IP_PUBLICA" > "$IP_ACT"

if [[ -f "$IP_ANT" ]]; then
    echo -e "\033[1;36m📌 IP anterior (Tor): $(cat "$IP_ANT")\033[0m"
else
    echo -e "\033[1;36m📌 IP anterior no disponible.\033[0m"
fi
echo -e "\033[1;36m🌐 IP actual (Tor): $IP_PUBLICA\033[0m"
cp "$IP_ACT" "$IP_ANT"

# === CAMBIO DE MAC ===
echo -e "\033[7;30m🎭 Cambiando MAC de la interfaz $INTERFAZ...\033[0m"
sudo ip link set "$INTERFAZ" down

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}')
echo "$MAC_ANTERIOR" > "$MC_ANT"

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
echo "$MAC_NUEVA" > "$MC_ACT"

sudo ip link set "$INTERFAZ" up

echo -e "\033[7;30m🔍 MAC anterior: $MAC_ANTERIOR\033[0m"
echo -e "\033[7;30m🎉 MAC asignada: $MAC_NUEVA\033[0m"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
