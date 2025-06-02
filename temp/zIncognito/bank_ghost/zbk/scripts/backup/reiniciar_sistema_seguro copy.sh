#!/bin/bash

# 🧩 Bloque 1: Configuración, creación de carpetas y dependencias

# === CONFIGURACIÓN ===
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
CACHE_DIR="$PROJECT_DIR/tmp/ghostcache"
LOG_DIR="$PROJECT_DIR/logs"
LOGFILE="$LOG_DIR/red.log"
PIDFILE="$CACHE_DIR/gunicorn.pid"
GUNICORN_LOG="$LOG_DIR/gunicorn_error.log"
PORT=8011
INTERFAZ="wlan0"
URL="http://0.0.0.0:$PORT/ghostrecon/dashboard/"

mkdir -p "$CACHE_DIR" "$LOG_DIR"

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

# Servicios internos
sudo ufw allow from 0.0.0.0 to any port 8000 proto tcp comment "Gunicorn_Ghost"
sudo ufw allow from 0.0.0.0 to any port 8001 proto tcp comment "Gunicorn_Api"
sudo ufw allow from 127.0.0.1 to any port 9050 proto tcp comment "Tor SOCKS5"
sudo ufw allow from 127.0.0.1 to any port 9051 proto tcp comment "Tor ControlPort"
sudo ufw allow from 0.0.0.0 to any port 5000 proto tcp comment "Flask (si se usa)"

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


# 🧩 Bloque 4: Verificar Tor, reintentar si no corre, conexión
echo "🕵️ Verificando si Tor está activo..."
if ! pgrep tor > /dev/null; then
    echo "⚠️ Tor no está activo. Intentando iniciar..."
    sudo systemctl restart tor || {
        echo "❌ No se pudo reiniciar Tor. Intentando instalarlo..."
        sudo apt-get update && sudo apt-get install tor -y

        sudo systemctl enable tor
        sudo systemctl start tor
    }
else
    echo "✅ Tor ya está corriendo."
fi

echo "🌍 Verificando conexión a través de Tor..."
torify curl -s https://check.torproject.org/ | grep -q "Congratulations"
if [ $? -eq 0 ]; then
    echo "🟢 Conexión Tor funcionando correctamente."
else
    echo "🔴 Falló la conexión Tor. Verifica configuración manualmente."
fi


# 🧩 Bloque 4: Verificar Tor, reintentar si no corre, conexión
echo "🕵️ Verificando si Tor está activo..."
if ! pgrep tor > /dev/null; then
    echo "⚠️ Tor no está activo. Intentando iniciar..."
    sudo systemctl restart tor || {
        echo "❌ No se pudo reiniciar Tor. Intentando instalarlo..."
        sudo apt update && sudo apt install tor -y
        sudo systemctl enable tor
        sudo systemctl start tor
    }
else
    echo "✅ Tor ya está corriendo."
fi

echo "🌍 Verificando conexión a través de Tor..."
torify curl -s https://check.torproject.org/ | grep -q "Congratulations"
if [ $? -eq 0 ]; then
    echo "🟢 Conexión Tor funcionando correctamente."
else
    echo "🔴 Falló la conexión Tor. Verifica configuración manualmente."
fi


# 🧩 Bloque 5: Dependencias del sistema, configuración Tor
if lsof -i tcp:$PORT > /dev/null; then
    echo "⚠️ Puerto $PORT en uso. Matando proceso..."
    PID_PORT=$(lsof -t -i tcp:$PORT)
    sudo kill -9 $PID_PORT
fi

echo "🐿 Instalando Tor y dependencias del sistema..."
sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
sudo apt install -y tor curl libpango-1.0-0 libgdk-pixbuf2.0-0 libffi-dev libssl-dev build-essential 

echo "🔧 Configurando Tor..."
sudo grep -q '^ControlPort' /etc/tor/torrc || echo 'ControlPort 9051' | sudo tee -a /etc/tor/torrc
sudo grep -q '^CookieAuthentication' /etc/tor/torrc || echo 'CookieAuthentication 1' | sudo tee -a /etc/tor/torrc
sudo systemctl enable tor
sudo systemctl start tor

if pgrep tor > /dev/null; then
    echo "🧅 TOR está activo ✅"
else
    echo "❌ TOR no está corriendo"
fi


# 🧩 Bloque 6: Lanzamiento de Gunicorn + navegador + notificación
source "$VENV_DIR/bin/activate"
python3 manage.py collectstatic --noinput

echo "🚀 Iniciando Gunicorn en 0.0.0.0:$PORT"
gunicorn bank_ghost.wsgi:application \
  --bind 0.0.0.0:$PORT \
  --workers 3 \
  --daemon \
  --pid "$PIDFILE" \
  --error-logfile "$GUNICORN_LOG"

for i in {1..10}; do
    if nc -z 0.0.0.0 $PORT; then
        echo "✅ Gunicorn escuchando en el puerto $PORT."
        break
    fi
    echo "⏳ Esperando que Gunicorn levante el servicio..."
    sleep 3
done

if ! nc -z 0.0.0.0 $PORT; then
    echo "❌ Gunicorn no pudo iniciarse en el puerto $PORT"
    exit 1
fi

echo -e "\n\033[1;32m✅ Ghost Recon iniciado en:\033[0m $URL"
notify-send "Ghost Recon" "✅ Proyecto iniciado correctamente en \n$URL"

