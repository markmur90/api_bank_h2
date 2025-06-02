#!/bin/bash

echo -e "[1;36m➡️ 🛑 Deteniendo servicios y procesos de Ghost Recon...[0m"
sleep 1

PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
PROJECT_NAME="bank_ghost"
SOCK_FILE="$PROJECT_DIR/ghost.sock"



# 1. Detener Gunicorn vía supervisor (si está configurado)
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 📦 Deteniendo Gunicorn (Supervisor)...[0m"
sleep 1
if sudo supervisorctl status $PROJECT_NAME &>/dev/null; then
    sudo supervisorctl stop $PROJECT_NAME
fi


# 2. Detener procesos Gunicorn residuales antes de borrar socket
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 🔪 Matando procesos gunicorn residuales...[0m"
sleep 1
pkill -f gunicorn 2>/dev/null || echo "⚠️  No hay procesos gunicorn activos."


# 3. Eliminar socket si aún existe
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
if [ -S "$SOCK_FILE" ]; then
    echo -e "[1;36m➡️ 🧹 Eliminando socket: $SOCK_FILE[0m"
sleep 1
    rm -f "$SOCK_FILE"
else
    echo -e "[1;36m➡️ 🧼 Socket ya no existe, limpio.[0m"
sleep 1
fi


# 4. Detener NGINX si está activo
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 🌐 Deteniendo NGINX...[0m"
sleep 1
sudo systemctl stop nginx || echo "⚠️  NGINX ya estaba detenido."


# === Liberar puertos usados por Gunicorn o procesos colgados ===
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 🔓 Liberando puertos usados (8000–8090)...[0m"
sleep 1

for port in $(seq 8000 8090); do
    PIDS=$(sudo lsof -ti tcp:$port)
    if [ ! -z "$PIDS" ]; then
        echo -e "[1;36m➡️ ⚠ Puerto $port en uso por PID(s): $PIDS[0m"
sleep 1
        for pid in $PIDS; do
            sudo kill -9 $pid && echo "🔪 Proceso $pid eliminado."
        done
    fi
done

# === Matar procesos Gunicorn explícitamente si quedaran colgados ===
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 🕵️ Matar procesos Gunicorn explícitamente si quedaran colgados...[0m"

RESIDUAL=$(pgrep -f "gunicorn.*bank_ghost")
if [ ! -z "$RESIDUAL" ]; then
    echo -e "[1;36m➡️ ⚠ Procesos Gunicorn activos: $RESIDUAL[0m"
sleep 1
    echo "$RESIDUAL" | xargs sudo kill -9
    echo -e "[1;32m✅ Gunicorn residual eliminado.[0m"
else
    echo -e "[1;32m✅ No hay procesos gunicorn activos.[0m"
fi

echo -e "[1;32m✅ Todo detenido y limpio. Ghost Recon ha sido apagado correctamente.[0m"




# =========================== z03 ===========================
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m\n"
echo -e "\033[1;36m➡️ 🧼 Limpiando entorno Ghost Recon...\033[0m"
sleep 1

PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/cron_ghost.log"

# Eliminar socket si existe
[ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo -e "\033[1;36m➡️ 🗑️ Socket eliminado.\033[0m"

# Eliminar logs temporales
find "$LOG_DIR" -type f -name 'cron_output_*.log' -delete && echo -e "\033[1;36m➡️ 🧹 Logs temporales eliminados.\033[0m"

# Truncar log principal de forma segura
if [ -f "$LOG_FILE" ]; then
    if [ -w "$LOG_FILE" ]; then
        truncate -s 0 "$LOG_FILE" && echo -e "\033[1;36m➡️ 🧾 Log principal truncado.\033[0m"
    else
        sudo truncate -s 0 "$LOG_FILE" && echo -e "\033[1;36m➡️ 🧾 Log principal truncado (con sudo).\033[0m"
    fi
else
    echo -e "\033[1;33m⚠️ El archivo de log principal no existe: $LOG_FILE\033[0m"
fi

# Matar procesos asociados al proyecto
pkill -u $(whoami) -f gunicorn 2>/dev/null
pkill -u $(whoami) -f ghost_recon_ultimate.py 2>/dev/null
pkill -u $(whoami) -f cron_wrapper.py 2>/dev/null

echo -e "\033[1;32m✅ Limpieza completa.\033[0m"



# =========================== z04 ===========================
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"


PROJECT_NAME="bank_ghost"
PROJECT_NAME_SOCK="ghost"
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
# PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$PROJECT_DIR/venv"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
GUNICORN_LOG="$LOG_DIR/gunicorn.log"
ERROR_LOG="$LOG_DIR/error.log"
SUPERVISOR_CONF="/etc/supervisor/conf.d/${PROJECT_NAME}.conf"
NGINX_CONF="/etc/nginx/sites-available/${PROJECT_NAME}"
USER="markmur88"

echo -e "[1;36m➡️ 🚀 Iniciando configuración completa de $PROJECT_NAME...[0m"
sleep 1

# Verificar que el script no necesita ser root excepto donde se indique
if [ "$EUID" -eq 0 ]; then
    echo -e "[1;33m⚠️ No se recomienda ejecutar todo este script como root.[0m"
fi

# Crear usuario si no existe (requiere sudo)
# if ! id "$USER" &>/dev/null; then
#     echo "👤 Creando usuario $USER... (requiere privilegios)"
#     if command -v sudo &>/dev/null; then
#         sudo useradd -m -s /bin/bash "$USER"
#     else
#         echo "❌ 'sudo' no está disponible. No se puede crear el usuario."
#         exit 1
#     fi
# fi

# Crear entorno virtual si no existe
# if [ ! -d "$VENV_DIR" ]; then
#     echo "🐍 Creando entorno virtual..."
#     python3 -m venv "$VENV_DIR"
# fi

# Activar entorno virtual
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
if [ -f "$VENV_DIR/bin/activate" ]; then
    echo -e "[1;32m✅ Activando entorno virtual...[0m"
    source "$VENV_DIR/bin/activate"
else
    echo -e "[1;31m❌ No se encontró el script de activación del entorno virtual.[0m"
    exit 1
fi

# Instalar requerimientos si el archivo existe
# echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
# REQ_FILE="$PROJECT_DIR/requirements.txt"
# if [ -f "$REQ_FILE" ]; then
#     echo -e "[1;36m➡️ 📦 Instalando dependencias desde $REQ_FILE...[0m"
# sleep 1
#     pip install --upgrade pip
#     pip install -r "$REQ_FILE"
# else
#     echo -e "[1;33m⚠️ No se encontró requirements.txt en $PROJECT_DIR.[0m"
# fi

# Crear carpeta de logs si no existe
# mkdir -p "$LOG_DIR"

# Preparar supervisord config (requiere sudo)
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
if [ ! -f "$SUPERVISOR_CONF" ]; then
    echo -e "[1;36m➡️ 📄 Creando configuración de Supervisor...[0m"
sleep 1
    if command -v sudo &>/dev/null; then
        sudo tee "$SUPERVISOR_CONF" > /dev/null <<EOF
[program:${PROJECT_NAME}]
directory=${PROJECT_DIR}
command=${VENV_DIR}/bin/gunicorn ${PROJECT_NAME}.wsgi:application --bind unix:${SOCK_FILE}
autostart=true
autorestart=true
stderr_logfile=${ERROR_LOG}
stdout_logfile=${GUNICORN_LOG}
user=${USER}
EOF
    else
        echo -e "[1;31m❌ No se puede escribir en /etc sin sudo. Skipping...[0m"
    fi
else
    echo -e "[1;36m➡️ ℹ️ Configuración de Supervisor ya existe, no se sobrescribe.[0m"
sleep 1
fi

# Preparar configuración de Nginx (requiere sudo)
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
if [ ! -f "$NGINX_CONF" ]; then
    echo -e "[1;36m➡️ 🌐 Creando configuración de Nginx...[0m"
sleep 1
    if command -v sudo &>/dev/null; then
        sudo tee "$NGINX_CONF" > /dev/null <<EOF
# AUTO-GENERATED NGINX CONF WITH SELF-SIGNED CERT
server {
    listen 80;
    server_name localhost;

    location / {
        include proxy_params;
        proxy_pass http://unix:${SOCK_FILE};
    }

    access_log ${LOG_DIR}/nginx_access.log;
    error_log ${LOG_DIR}/nginx_error.log;
}
EOF
        sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/"
    else
        echo -e "[1;31m❌ No se puede configurar nginx sin sudo. Skipping...[0m"
    fi
else
    echo -e "[1;36m➡️ ℹ️ Configuración de Nginx ya existe, no se sobrescribe.[0m"
sleep 1
fi

echo -e "[1;36m➡️ 🎉 Script completado. Revisa los mensajes anteriores para acciones manuales pendientes.[0m"
sleep 1

echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"

# =========================== x01 ===========================



PROJECT_NAME="bank_ghost"
PROJECT_NAME_SOCK="ghost"
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
VENV_DIR="$PROJECT_DIR/venv"
SOCK_FILE="$PROJECT_DIR/ghost.sock"
LOG_DIR="$PROJECT_DIR/logs"
GUNICORN_LOG="$LOG_DIR/gunicorn.log"
ERROR_LOG="$LOG_DIR/error.log"

echo -e "[1;36m➡️ 🚀 Iniciando creación de socket para Gunicorn...[0m"
sleep 1
mkdir -p "$LOG_DIR"
[ -S "$SOCK_FILE" ] && rm -f "$SOCK_FILE" && echo "🗑️ Socket eliminado."
cd "$PROJECT_DIR"
echo -e "[1;32m✅ Activando entorno virtual...[0m"
source "$VENV_DIR/bin/activate"
echo -e "[1;36m➡️ 🔧 Exportando DJANGO_SETTINGS_MODULE...[0m"
sleep 1
export DJANGO_SETTINGS_MODULE="bank_ghost.settings"
echo -e "[1;36m➡️ 🔥 Iniciando Gunicorn en "$SOCK_FILE"[0m"
sleep 1
"$VENV_DIR/bin/gunicorn" bank_ghost.wsgi:application --chdir "$PROJECT_DIR" --bind "unix:$SOCK_FILE" --workers 3 --log-file "$GUNICORN_LOG" --error-logfile "$ERROR_LOG" &
sleep 2

if [ -S "$SOCK_FILE" ]; then
    echo -e "[1;32m✅ Socket creado en "$SOCK_FILE"[0m"
    echo -e "[1;36m➡️ 🔒 Ajustando permisos...[0m"
sleep 1
    chown "$(whoami)":www-data "$SOCK_FILE"
    chmod 660 "$SOCK_FILE"
    echo -e "[1;36m➡️ 🔍 Verificando permisos finales:[0m"
sleep 1
    ls -l "$SOCK_FILE"
    echo -e "[1;32m✅ Gunicorn y socket configurados correctamente.[0m"
else
    echo -e "[1;31m❌ No se pudo crear el socket en "$SOCK_FILE"[0m"
    echo -e "[1;36m➡️ 📛 Revisa "$ERROR_LOG" para ver la traza de error de Gunicorn[0m"
sleep 1
    exit 2
fi


# =========================== x03 ===========================



# 🧩 Bloque 1: Configuración, creación de carpetas y dependencias

# === CONFIGURACIÓN ===
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
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

#mkdir -p "$CACHE_DIR" "$LOG_DIR"

# Verificar dependencias necesarias
echo -e "[1;36m➡️ 🕵️ Verificando dependencias macchanger hostname...[0m"

if ! command -v macchanger &> /dev/null; then
    echo -e "[1;36m➡️ 🔧 Instalando macchanger...[0m"
sleep 1
    sudo apt install macchanger -y
fi
if ! command -v hostname &> /dev/null; then
    echo -e "[1;36m➡️ 🔧 Instalando hostname...[0m"
sleep 1
    sudo apt install hostname -y
fi

# 🧩 Bloque 2: Configuración del firewall y cambio de IP/MAC
# === A. CONFIGURACIÓN DEL FIREWALL ===
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
echo -e "[1;36m➡️ 🛡️ Configurando firewall UFW...[0m"
sleep 1

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
echo -e "[1;32m✅ UFW configurado correctamente[0m"
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"





echo -e "\n\033[7;30m🔁 Cambiando MAC de la interfaz $INTERFAZ\033[0m" | tee -a "$LOGFILE"
sudo ip link set "$INTERFAZ" up
sleep 2
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"

MAC_ANTERIOR=$(sudo macchanger -s "$INTERFAZ" | awk '/Current MAC:/ {print $3}' || echo "No disponible")
IP_ANTERIOR=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
IP_ANTERIOR=${IP_ANTERIOR:-"No disponible"}
FILE_MAC_ANT=$CACHE_DIR/mac_antes.txt
FILE_MAC_ACT=$CACHE_DIR/mac_actual.txt
FILE_IP_ANT=$CACHE_DIR/ip_antes.txt
FILE_IP_ACT=$CACHE_DIR/ip_actual.txt


echo -e "[1;36m➡️ "$MAC_ANTERIOR" > "$FILE_MAC_ANT"[0m"
sleep 1
echo -e "[1;36m➡️ "$IP_ANTERIOR"  > "$FILE_IP_ANT"[0m"
sleep 1

echo -e "[1;36m➡️ 📤 Liberando IP actual...[0m"
sleep 1
sudo dhclient -r "$INTERFAZ"
sudo ip link set "$INTERFAZ" down

MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
sudo ip link set "$INTERFAZ" up
sleep 2
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"


# 🧩 Bloque 3: Renegociar IP, verificar cambio, loguear resultado

RAND_HOST="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)"
echo -e "[1;36m➡️ 📥 Solicitando nueva IP con hostname aleatorio $RAND_HOST...[0m"
echo ""
sleep 1
sudo HOSTNAME="$RAND_HOST" dhclient -v "$INTERFAZ"
sleep 5

IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
IP_ACTUAL=${IP_ACTUAL:-"No disponible"}
echo "$IP_ACTUAL" > "$FILE_IP_ACT"
echo ""
echo -e "\033[1;36m➡️ IP actual registrada: $IP_ACTUAL\033[0m"
echo ""
sleep 1

if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
    echo -e "\033[1;36m➡️ ⚠ IP no ha cambiado tras el cambio de MAC. Reintentando...\033[0m"
    echo ""
    sleep 1
    sudo ip link set "$INTERFAZ" down
    MAC_NUEVA=$(sudo macchanger -r "$INTERFAZ" | awk '/New MAC:/ {print $3}')
    sudo ip link set "$INTERFAZ" up
    sleep 2
    RAND_HOST="ghost-$(tr -dc a-z0-9 </dev/urandom | head -c6)"
    echo -e "\033[1;36m➡️ 📥 Segundo intento con hostname aleatorio $RAND_HOST...\033[0m"
    echo ""
    sleep 1
    sudo HOSTNAME="$RAND_HOST" dhclient -v "$INTERFAZ"
    sleep 5

    IP_ACTUAL=$(ip -4 addr show "$INTERFAZ" | awk '/inet / {print $2}' | cut -d/ -f1)
    IP_ACTUAL=${IP_ACTUAL:-"No disponible"}
    echo "$IP_ACTUAL" > "$FILE_IP_ACT"
    echo ""
    echo -e "\033[1;36m➡️ IP actual registrada tras segundo intento: $IP_ACTUAL\033[0m"
    echo ""
    sleep 1

    if [ "$IP_ACTUAL" = "$IP_ANTERIOR" ]; then
        echo -e "\033[1;33m⚠️ La IP no cambió tras dos intentos. Posible rastreo por DHCP persistente.\033[0m"
        echo ""
    fi
fi

echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m\n"







FECHA="$(date '+%Y-%m-%d %H:%M:%S')"
{
  echo -e "[1;36m➡️ =========================================[0m"
sleep 1
  echo -e "[1;36m➡️ 🔁 Cambio de red realizado ($FECHA)[0m"
sleep 1
  echo -e "[1;36m➡️ 🖧 Interfaz: $INTERFAZ[0m"
sleep 1
  echo -e "[1;36m➡️ 🔍 MAC anterior: $MAC_ANTERIOR[0m"
sleep 1
  echo -e "[1;36m➡️ 🎉 MAC actual:   $MAC_NUEVA[0m"
sleep 1
  echo -e "[1;36m➡️ 🌐 IP anterior:  $IP_ANTERIOR[0m"
sleep 1
  echo -e "[1;36m➡️ 🌐 IP actual:    $IP_ACTUAL[0m"
sleep 1
  echo -e "[1;36m➡️ =========================================[0m"
sleep 1
} | tee -a "$LOGFILE"

echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"






# 🧩 Bloque 4: Verificar Tor, reintentar si no corre, conexión
echo -e "[1;36m➡️ 🕵️ Verificando si Tor está activo...[0m"
echo -e "[1;36m➡️ 🔧 Configurando Tor...[0m"
sleep 1
sudo grep -q '^ControlPort' /etc/tor/torrc || echo 'ControlPort 9051' | sudo tee -a /etc/tor/torrc
sudo grep -q '^CookieAuthentication' /etc/tor/torrc || echo 'CookieAuthentication 0' | sudo tee -a /etc/tor/torrc


if ! pgrep tor > /dev/null; then
    echo -e "[1;33m⚠️ Tor no está activo. Intentando iniciar...[0m"
    sudo systemctl restart tor || {
        echo -e "[1;31m❌ No se pudo reiniciar Tor. Intentando instalarlo...[0m"
        sudo apt update && sudo apt install tor -y
        sudo systemctl enable tor
        sudo systemctl start tor
    }
else
    echo -e "[1;32m✅ Tor ya está corriendo.[0m"
fi
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"

# 🧩 Bloque 5: Dependencias del sistema, configuración Tor
echo -e "[1;36m➡️ Cerrando puetos...[0m"

if lsof -i tcp:$PORT > /dev/null; then
    echo -e "[1;33m⚠️ Puerto $PORT en uso. Matando proceso...[0m"
    PID_PORT=$(lsof -t -i tcp:$PORT)
    sudo kill -9 $PID_PORT
fi

echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"



TOR_PASS="Ptf8454Jd55"
PROJECT_NAME="bank_ghost"

echo -e "\n\033[1;34m🔐 Verificando autenticación por contraseña en ControlPort 9051...\033[0m"

CHECK_TOR_CTRL=$(echo -e "AUTHENTICATE \"$TOR_PASS\"\r\nSIGNAL NEWNYM\r\nQUIT\r\n" | nc 127.0.0.1 9051)

if echo "$CHECK_TOR_CTRL" | grep -q "250 OK"; then
    echo -e "\033[1;32m🟢 Tor respondió correctamente al control:\033[0m\n$CHECK_TOR_CTRL"
else
    echo -e "\033[1;31m🔴 Error de autenticación o control:\033[0m\n$CHECK_TOR_CTRL"
    echo -e "\033[1;33m⚠️ Asegúrate de que el hash de la contraseña esté bien configurado en /etc/tor/torrc\033[0m"
    exit 1
fi

echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m\n"

echo -e "\033[1;36m🧩 Activando y levantando servicio Supervisor para $PROJECT_NAME...\033[0m"
sudo supervisorctl enable "$PROJECT_NAME"
sudo supervisorctl start "$PROJECT_NAME"

echo -e "\n\033[1;36m📦 Recolectando archivos estáticos...\033[0m"
sleep 1
STATIC_SUMMARY=$(python3 manage.py collectstatic --noinput 2>&1)
echo -e "\033[1;36m$STATIC_SUMMARY\033[0m"

echo -e "\n\033[1;36m🚀 Iniciando Gunicorn en 0.0.0.0:8011...\033[0m"
sleep 1
source venv/bin/activate
nohup venv/bin/gunicorn bank_ghost.wsgi:application --bind '0.0.0.0:8011' --workers 3 > gunicorn.out 2>&1 &
sleep 2

if ss -tunlp | grep -q ':8011'; then
    echo -e "\033[1;32m✅ Gunicorn escuchando en el puerto 8011.\033[0m"
else
    echo -e "\033[1;31m❌ Gunicorn no pudo iniciarse.\033[0m"
    exit 1
fi

echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
echo -e "🔍 \033[1;36mVerificando puertos 80 y 443 para NGINX...\033[0m"

for port in 80 443; do
    if sudo lsof -i :$port >/dev/null 2>&1; then
        echo -e "⚠️  Puerto $port en uso:"
        sudo lsof -i :$port
        read -p "❓ ¿Deseás cerrar estos procesos para permitir que NGINX use el puerto $port? [s/N]: " RESP
        if [[ "$RESP" =~ ^[Ss]$ ]]; then
            sudo lsof -t -i :$port | xargs -r sudo kill -9
            echo -e "✅ Puerto $port liberado."
        else
            echo -e "🚫 No se liberó el puerto $port. Podría haber conflictos con NGINX."
        fi
    else
        echo -e "✅ Puerto $port está libre."
    fi
done

echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
echo -e "🔍 \033[1;36mVerificando puertos 80 y 443 para NGINX...\033[0m"

for port in 80 443; do
    if sudo lsof -i :$port >/dev/null 2>&1; then
        echo -e "⚠️  Puerto $port en uso:"
        sudo lsof -i :$port
        read -p "❓ ¿Deseás cerrar estos procesos para permitir que NGINX use el puerto $port? [s/N]: " RESP
        if [[ "$RESP" =~ ^[Ss]$ ]]; then
            sudo lsof -t -i :$port | xargs -r sudo kill -9
            echo -e "✅ Puerto $port liberado."
        else
            echo -e "🚫 No se liberó el puerto $port. Podría haber conflictos con NGINX."
        fi
    else
        echo -e "✅ Puerto $port está libre."
    fi
done

# Certificados SSL
SSL_DIR="/etc/ssl/bank_ghost"
CRT="$SSL_DIR/ghost.crt"
KEY="$SSL_DIR/ghost.key"

if [[ ! -f "$CRT" || ! -f "$KEY" ]]; then
    echo -e "\n\033[1;36m🔐 Certificados no encontrados. Generando autofirmado...\033[0m"
    sudo mkdir -p "$SSL_DIR"
    sudo openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$KEY" \
        -out "$CRT" \
        -subj "/C=DE/ST=Hessen/L=Frankfurt/O=GhostRecon/OU=Dev/CN=localhost"
    echo -e "✅ Certificados creados."
else
    echo -e "✅ Certificados SSL ya existen."
fi

# Verificación NGINX
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
echo -e "🔍 Verificando configuración NGINX..."

if sudo nginx -t; then
    echo -e "\033[1;32m✅ Configuración NGINX válida.\033[0m"
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo -e "\033[1;32m✅ NGINX iniciado y habilitado al arranque.\033[0m"
else
    echo -e "\033[1;31m❌ Error en configuración de NGINX. Abortando inicio.\033[0m"
fi

# Supervisor
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
echo -e "🔍 Verificando estado de Supervisor..."

if ! systemctl is-active --quiet supervisor; then
    echo -e "⚠️ Supervisor está detenido. Iniciando..."
    sudo systemctl start supervisor
    sudo systemctl enable supervisor
    echo -e "✅ Supervisor activo y habilitado."
else
    echo -e "✅ Supervisor ya está activo."
fi

# Iniciar programa bajo Supervisor
echo -e "🔍 Verificando programa 'bank_ghost' en Supervisor..."
if sudo supervisorctl status bank_ghost 2>/dev/null | grep -q RUNNING; then
    echo -e "✅ 'bank_ghost' ya se está ejecutando bajo Supervisor."
else
    echo -e "🚀 Iniciando 'bank_ghost' en Supervisor..."
    sudo supervisorctl reread
    sudo supervisorctl update
    sudo supervisorctl start bank_ghost
fi

# Notificación y log
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"
FECHA="$(date '+%Y-%m-%d %H:%M:%S')"
MSG="✅ Ghost Recon operativo a las $FECHA"
echo -e "\n$MSG" | tee -a "$PROJECT_DIR/logs/estado_inicio.log"
notify-send "Ghost Recon" "$MSG"

echo -e "\033[1;32m🎯 Todo listo. Sistema en marcha.\033[0m"
echo -e "\n\033[1;34m────────────────────────────────────────────────────────────\033[0m"


# Abrir navegador
# ====================
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"
URL="http://0.0.0.0:$PORT/ghostrecon/dashboard/"
echo "🌐 Abriendo interfaz en el navegador..."
firefox --new-window "$URL" > /dev/null 2>&1 &

echo -e "\n\033[1;32m✅ Ghost Recon iniciado en:\033[0m $URL"
notify-send "Ghost Recon" "✅ Proyecto iniciado correctamente en \n$URL"


# =========================== x05 ===========================
echo -e "\n[1;34m────────────────────────────────────────────────────────────[0m\n"