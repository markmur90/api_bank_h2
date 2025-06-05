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

