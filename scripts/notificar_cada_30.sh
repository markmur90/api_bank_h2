#!/usr/bin/env bash
set -e

MENSAJE="${1:-⏰ Recordatorio: revisá el estado del servidor Njalla}"
INTERVALO_MINUTOS="${2:-30}"
INTERVALO_SEGUNDOS=$((INTERVALO_MINUTOS * 60))

echo "🟢 Notificaciones activadas cada $INTERVALO_MINUTOS minutos."

while true; do
    DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus \
    notify-send -u critical -a "VPS Njalla" -t 10000 "🔔 VPS Njalla" "$MENSAJE"
    sleep "$INTERVALO_SEGUNDOS"
done
