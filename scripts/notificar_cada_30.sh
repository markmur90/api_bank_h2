#!/usr/bin/env bash
set -e

MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

while true; do
    # Notifica de inmediato al iniciar
    notify-send "🔔 " "$MENSAJE"

    # Calcula segundos restantes para el próximo múltiplo de 30 min
    ahora=$(date +%s)
    minuto_actual=$(date +%M)
    segundo_actual=$(date +%S)

    proximo=$(date -d "next *:${INTERVALO_MINUTOS} past" +%s)
    if (( minuto_actual % INTERVALO_MINUTOS == 0 )); then
        proximo=$(( ahora + INTERVALO_MINUTOS * 60 ))
    fi

    espera=$(( proximo - ahora - segundo_actual ))
    sleep "$espera"
done
