#!/usr/bin/env bash
set -e

echo -e "\n📋 \033[1;36mNotificadores activos detectados:\033[0m"

# Detectar procesos
procs=$(pgrep -af 'notificador(_30)?\.sh')

if [ -z "$procs" ]; then
    echo "❌ No se detectaron procesos de notificación en ejecución."
    exit 0
fi

echo "$procs" | awk '{ printf "🔸 PID: \033[1;33m%s\033[0m - CMD: %s\n", $1, substr($0, index($0,$2)) }'

# Preguntar acción
echo -ne "\n❓ ¿Qué querés hacer?\n"
echo "   [k] Kill (terminar todos los procesos)"
echo "   [r] Restart (solo reiniciar notificar_vps.service)"
echo "   [s] Saltar"
read -p "👉 Acción (k/r/s): " acc

case "$acc" in
  k|K)
    echo "$procs" | awk '{print $1}' | xargs kill -9
    echo "✅ Todos los procesos de notificación fueron terminados."
    ;;
  r|R)
    systemctl --user restart notificar_vps.service && echo "🔁 Servicio notificador reiniciado."
    ;;
  *)
    echo "ℹ️ Operación cancelada."
    ;;
esac
