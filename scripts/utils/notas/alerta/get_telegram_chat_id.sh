#!/bin/bash

# Pedimos el token
read -p "6983248274:AAH2qeYxpkIQR88prtuvt4YSJGAKU__wF4o" TG_TOKEN

# Obtenemos la info con curl
RESPONSE=$(curl -s "https://api.telegram.org/bot${TG_TOKEN}/getUpdates")

# Extraemos el chat_id del último mensaje recibido
CHAT_ID=$(echo "$RESPONSE" | grep -o '"chat":{"id":[0-9]*' | head -n 1 | grep -o '[0-9]*')

if [[ -n "$CHAT_ID" ]]; then
    echo -e "✅ Chat ID detectado: \033[1;32m$CHAT_ID\033[0m"
else
    echo -e "❌ No se pudo detectar el chat ID. Asegurate de haberle mandado un mensaje al bot."
fi
