# #!/bin/bash

# # 🧩 Bloque 1: Configuración, creación de carpetas y dependencias

# === CONFIGURACIÓN ===
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
# PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
CACHE_DIR="$PROJECT_DIR/tmp/ghostcache"
LOG_DIR="$PROJECT_DIR/logs"
LOGFILE="$LOG_DIR/red.log"
PIDFILE="$CACHE_DIR/gunicorn.pid"
GUNICORN_LOG="$LOG_DIR/gunicorn_error.log"
PORT=8011
INTERFAZ="wlan0"
URL="http://0.0.0.0:$PORT/ghostrecon/dashboard/"

# #mkdir -p "$CACHE_DIR" "$LOG_DIR"

DIVIDER="========================================"


start_block(){
  echo -e "\n$DIVIDER\n>> INICIO: $1\n$DIVIDER" | tee -a "$OPERATION_LOG"
}
end_block(){
  echo -e "$DIVIDER\n<< FIN:    $1\n$DIVIDER" | tee -a "$OPERATION_LOG"
}


# Verificar dependencias necesarias
if ! command -v macchanger &> /dev/null; then
    echo "🔧 Instalando macchanger..."
    sudo apt install macchanger -y
fi
if ! command -v hostname &> /dev/null; then
    echo "🔧 Instalando hostname..."
    sudo apt install hostname -y
fi

# 🧩 Bloque 2: Configuración del firewall y cambio de IP/MAC
# === A. CONFIGURACIÓN DEL FIREWALL ===
echo "🛡️ Configurando firewall UFW..."

sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 80/tcp    # Nginx HTTP
sudo ufw allow 443/tcp   # Nginx HTTPS
sudo ufw allow 2222/tcp  # Honeypot Cowrie SSH
sudo ufw allow 8000/tcp
sudo ufw allow 8001/tcp
sudo ufw allow 8011/tcp
sudo ufw allow 9050/tcp
sudo ufw allow 9051/tcp


sudo ufw --force enable
echo "✅ UFW configurado correctamente"


echo -e "\n\033[7;30m🔁 Cambiando MAC de la interfaz $INTERFAZ\033[0m" | tee -a "$LOGFILE"
sudo ip link set "$INTERFAZ" up
sleep 2

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}' || echo "No disponible")
IP_ANTERIOR=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
IP_ANTERIOR=${IP_ANTERIOR:-"No disponible"}

echo "$MAC_ANTERIOR" > "$CACHE_DIR/mac_antes.txt"
echo "$IP_ANTERIOR"  > "$CACHE_DIR/ip_antes.txt"

echo "📤 Liberando IP actual..."
sudo dhclient -r "$INTERFAZ"
sudo ip link set "$INTERFAZ" down

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
sudo ip link set "$INTERFAZ" up
sleep 2


# 🧩 Bloque 3: Renegociar IP, verificar cambio, loguear resultado

RAND_HOST="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)"
echo "📥 Solicitando nueva IP con hostname aleatorio $RAND_HOST..."
sudo HOSTNAME="$RAND_HOST" dhclient -v "$INTERFAZ"
sleep 5

IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
IP_ACTUAL=${IP_ACTUAL:-"No disponible"}
echo "$IP_ACTUAL" > "$CACHE_DIR/ip_actual.txt"

if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
    echo "⚠ IP no ha cambiado tras el cambio de MAC. Reintentando..."
    sudo ip link set "$INTERFAZ" down
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    sleep 2
    RAND_HOST="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)"
    echo "📥 Segundo intento con hostname aleatorio $RAND_HOST..."
    sudo HOSTNAME="$RAND_HOST" dhclient -v "$INTERFAZ"
    sleep 5

    IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
    IP_ACTUAL=${IP_ACTUAL:-"No disponible"}
    echo "$IP_ACTUAL" > "$CACHE_DIR/ip_actual.txt"

    if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
        echo "⚠️ La IP no cambió tras dos intentos. Posible rastreo por DHCP persistente."
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
} | tee -a "$LOGFILE"







# # 🧩 Bloque 4: Verificar Tor, reintentar si no corre, conexión
# echo "🕵️ Verificando si Tor está activo..."
# echo "🔧 Configurando Tor..."
# sudo grep -q '^ControlPort' /etc/tor/torrc || echo 'ControlPort 9051' | sudo tee -a /etc/tor/torrc
# sudo grep -q '^CookieAuthentication' /etc/tor/torrc || echo 'CookieAuthentication 0' | sudo tee -a /etc/tor/torrc


# if ! pgrep tor > /dev/null; then
#     echo "⚠️ Tor no está activo. Intentando iniciar..."
#     sudo systemctl restart tor || {
#         echo "❌ No se pudo reiniciar Tor. Intentando instalarlo..."
#         sudo apt update && sudo apt install tor -y
#         sudo systemctl enable tor
#         sudo systemctl start tor
#     }
# else
#     echo "✅ Tor ya está corriendo."
# fi

# # 🧩 Bloque 5: Dependencias del sistema, configuración Tor
# if lsof -i tcp:$PORT > /dev/null; then
#     echo "⚠️ Puerto $PORT en uso. Matando proceso..."
#     PID_PORT=$(lsof -t -i tcp:$PORT)
#     sudo kill -9 $PID_PORT
# fi




# TOR_PASS="Ptf8454Jd55"

# echo -e "\n🔐 Verificando autenticación por contraseña en ControlPort 9051..."

# CHECK_TOR_CTRL=$(echo -e "AUTHENTICATE \"$TOR_PASS\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc 127.0.0.1 9051)

# if echo "$CHECK_TOR_CTRL" | grep -q "250 OK"; then
#     echo -e "🟢 Tor respondió correctamente al control:\n$CHECK_TOR_CTRL"
# else
#     echo -e "🔴 Error de autenticación o control:\n$CHECK_TOR_CTRL"
#     echo "⚠️ Asegúrate de que el hash de la contraseña esté bien configurado en /etc/tor/torrc"
# fi


# echo "📦 Recolectando archivos estáticos..."
# STATIC_SUMMARY=$(python3 manage.py collectstatic --noinput)
# echo "$STATIC_SUMMARY"
# echo "🚀 Iniciando Gunicorn en 0.0.0.0:8011"
# source venv/bin/activate
# nohup venv/bin/gunicorn bank_ghost.wsgi:application --bind '0.0.0.0:8011' --workers 3 >gunicorn.out 2>&1 &
# sleep 2
# if ss -tunlp | grep -q ':8011'; then
#     echo "✅ Gunicorn escuchando en el puerto 8011."
# else
#     echo "❌ Gunicorn no pudo iniciarse."
#     exit 1
# fi

# ====================
# Abrir navegador
# ====================
# URL="http://0.0.0.0:$PORT/ghostrecon/dashboard/"
# echo "🌐 Abriendo interfaz en el navegador..."
# firefox --new-window "$URL" > /dev/null 2>&1 &

# echo -e "\n\033[1;32m✅ Ghost Recon iniciado en:\033[0m $URL"
# notify-send "Ghost Recon" "✅ Proyecto iniciado correctamente en \n$URL"


# =========================== x05 ===========================


