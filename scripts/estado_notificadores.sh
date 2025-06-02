#!/usr/bin/env bash
echo -e "\n📡 Estado de los notificadores:\n"

# Verificar notificador.sh
if pgrep -f "/notificador.sh" > /dev/null; then
    echo "✅ notificador.sh está corriendo."
else
    echo "❌ notificador.sh no está activo."
fi

# Verificar notificador_30.sh
if pgrep -f "/notificador_30.sh" > /dev/null; then
    echo "✅ notificador_30.sh está corriendo."
else
    echo "❌ notificador_30.sh no está activo."
fi

# Verificar el servicio systemd
estado=$(systemctl --user is-active notificar_vps.service 2>/dev/null)
if [[ "$estado" == "active" ]]; then
    echo "✅ notificar_vps.service activo en systemd."
else
    echo "❌ notificar_vps.service está en estado: $estado"
fi
