#!/usr/bin/env bash
set -e

MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

while true; do
    HORA_LOCAL=$(date "+%H:%M:%S")
    HORA_BOGOTA=$(TZ=America/Bogota date "+%H:%M:%S")
    notify-send "🔔 VPS Njalla" "$MENSAJE\nLocal: $HORA_LOCAL | Bogotá: $HORA_BOGOTA"

    # Calcular segundos hasta el siguiente múltiplo de INTERVALO_MINUTOS
    ahora=$(date +%s)
    minutos=$(date +%M)
    segundos=$(date +%S)
    total_pasados=$((10#${minutos} * 60 + 10#${segundos}))
    intervalo_segundos=$((INTERVALO_MINUTOS * 60))
    restante=$((intervalo_segundos - (total_pasados % intervalo_segundos)))

    sleep "$restante"
done
