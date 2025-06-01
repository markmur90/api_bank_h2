#!/usr/bin/env bash
set -e

export DISPLAY=:0.0
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus


MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-10}"

# Ruta al archivo de sonido (asegúrate de que exista)
SONIDO="/usr/share/sounds/freedesktop/stereo/message.oga"

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

while true; do
    # Obtener la hora actual en ambas zonas horarias
    HORA_LOCAL=$(date '+%H:%M:%S')
    HORA_BOGOTA=$(TZ=America/Bogota date '+%H:%M:%S')

    # Enviar notificación visual con zenity y sonido en paralelo
    (
      zenity --info --title="🔔 VPS Njalla" \
        --text="$MENSAJE\nHora local: $HORA_LOCAL\nHora Bogotá: $HORA_BOGOTA" \
        --timeout=5
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
