#!/bin/bash
# 🔁 Sincroniza el archivo .onion desde el VPS al entorno local

# Configuración
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="/home/markmur88/.ssh/vps_njalla_nueva"
REMOTE_ONION="/home/markmur88/simulador_hostname.txt"
LOCAL_ONION="/home/markmur88/simulador_hostname.txt"

# Sincronizar archivo
echo "📥 Descargando archivo .onion desde el VPS..."
scp -P "$VPS_PORT" -i "$SSH_KEY" "$VPS_USER@$VPS_IP:$REMOTE_ONION" "$LOCAL_ONION"

if [ $? -eq 0 ]; then
    echo "✅ Archivo .onion actualizado localmente en: $LOCAL_ONION"
    cat "$LOCAL_ONION"
else
    echo "❌ Error al descargar el archivo .onion"
fi
