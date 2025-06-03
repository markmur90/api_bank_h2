#!/bin/bash

for service in notificador_bin.service notificador_30.service; do
    pid=$(systemctl --user show -p MainPID "$service" | cut -d'=' -f2)
    if [[ -z "$pid" || "$pid" == "0" ]]; then
        echo "❌ $service no activo o sin PID válido."
        continue
    fi

    echo "📋 Procesos relacionados con $service:"
    ps -p "$pid" -o pid,etime,cmd
    pgrep -P "$pid" | while read -r child; do
        ps -p "$child" -o pid,etime,cmd
    done

    echo -e "\n🔁 Reiniciando $service..."
    pkill -TERM -P "$pid"
    kill -TERM "$pid"
    systemctl --user restart "$service"
    echo "✅ $service reiniciado."
done
