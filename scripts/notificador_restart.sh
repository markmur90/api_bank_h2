#!/bin/bash

pid=$(systemctl --user show -p MainPID notificar_vps.service | cut -d'=' -f2)
if [[ -z "$pid" || "$pid" == "0" ]]; then
    echo "❌ Servicio no activo o sin PID válido."
    exit 1
fi

echo "📋 Procesos relacionados con notificar_vps.service:"
ps -p "$pid" -o pid,etime,cmd
pgrep -P "$pid" | while read -r child; do
    ps -p "$child" -o pid,etime,cmd
done

echo -ne "\n⚠️ ¿Querés reiniciar el servicio y matar estos procesos? (s/n): "
read -r confirm
if [[ "$confirm" =~ ^[sS]$ ]]; then
    pkill -TERM -P "$pid"
    kill -TERM "$pid"
    echo "⏳ Reiniciando servicio..."
    systemctl --user restart notificar_vps.service
    echo "✅ Servicio reiniciado."
else
    echo "ℹ️ Operación cancelada."
fi
