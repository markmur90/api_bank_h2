#!/usr/bin/env bash
set -e -x

# # --- logging ---
# mkdir -p "/home/markmur88/scripts/logs_notificadores"
# LOG_FILE="/home/markmur88/scripts/logs_notificadores/$(basename "$0").log"
# exec > >(tee -a "$LOG_FILE") 2>&1
# echo -e "\n🔄 Inicio $(date '+%F %T')"


export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus


MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"

# Ruta al archivo de sonido (asegúrate de que exista)
SONIDO="/usr/share/sounds/freedesktop/stereo/complete.oga"
TIEMPO_INICIO=$(date +%s)

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

# Evitar duplicados
if pgrep -f "notificador_30.sh 30" > /dev/null; then
  echo "⚠ Ya hay un notificador_30.sh corriendo con intervalo 30 minutos. Abortando."
  exit 1
fi

while true; do
    # Obtener la hora actual en ambas zonas horarias
    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')

    # Enviar notificación visual con zenity y sonido en paralelo
    TIEMPO_ACTUAL=$(date +%s)
    MINUTOS_TRANSCURRIDOS=$(( (TIEMPO_ACTUAL - TIEMPO_INICIO) / 60 ))

    (
    zenity --info \
        --title="🔔 Tiempo transcurrido: $MINUTOS_TRANSCURRIDOS minutos" \
        --text="$MENSAJE\nHora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA" \
        --timeout=3
    ) &
    paplay "$SONIDO" &

    # Calcular tiempo hasta el siguiente múltiplo exacto de INTERVALO_MINUTOS
    MINUTOS_ACTUALES=$(date +%M)
    SEGUNDOS_ACTUALES=$(date +%S)
    RESTO=$((MINUTOS_ACTUALES % INTERVALO_MINUTOS))
    ESPERA=$(( (INTERVALO_MINUTOS - RESTO) * 60 - SEGUNDOS_ACTUALES ))

    if [ "$ESPERA" -le 0 ]; then
        ESPERA=$((INTERVALO_MINUTOS * 60))
    fi

    sleep "$ESPERA"
done
