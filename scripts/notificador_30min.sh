#!/usr/bin/env bash
set -e

MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"
INTERVALO_SEGUNDOS=$((INTERVALO_MINUTOS * 60))

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos."
while true; do
    notify-send "🔔 VPS Njalla" "$MENSAJE"
    sleep "$INTERVALO_SEGUNDOS"
done
