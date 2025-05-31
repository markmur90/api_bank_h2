#!/usr/bin/env bash
set -e

MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos exactos del reloj."

while true; do
    ahora_local=$(date '+%H:%M:%S %Z')
    ahora_bogota=$(TZ=America/Bogota date '+%H:%M:%S %Z')

    cuerpo="💡 $MENSAJE\n🕒 Local: $ahora_local\n🌎 Bogotá: $ahora_bogota"
    notify-send "🔔 VPS Njalla" "$cuerpo"

    # Calcular segundos restantes para el próximo múltiplo de INTERVALO_MINUTOS
    ahora_s=$(date +%s)
    minuto_actual=$(date +%M)
    segundo_actual=$(date +%S)

    proximo=$(( ( ( (ahora_s / 60 + INTERVALO_MINUTOS) / INTERVALO_MINUTOS ) * INTERVALO_MINUTOS * 60 ) ))
    espera=$(( proximo - ahora_s ))
    sleep "$espera"
done