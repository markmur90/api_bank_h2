#!/bin/bash

TG_CONFIG="$HOME/.telegram_bot.conf"

guardar_config() {
    echo "TG_TOKEN=\"$TG_TOKEN\"" > "$TG_CONFIG"
    echo "TG_CHAT_ID=\"$TG_CHAT_ID\"" >> "$TG_CONFIG"
    echo -e "\n✅ Configuración guardada en $TG_CONFIG"
}

cargar_config() {
    if [ -f "$TG_CONFIG" ]; then
        source "$TG_CONFIG"
    fi
}

detectar_chat_id() {
    echo -e "\n📥 Pegá tu TOKEN del bot de Telegram:"
    read -r TG_TOKEN

    echo -e "\n📡 Esperando que le mandes un mensaje al bot..."
    sleep 2
    curl -s "https://api.telegram.org/bot${TG_TOKEN}/getUpdates" > /tmp/tg_response.json

    TG_CHAT_ID=$(grep -o '"chat":{"id":[0-9]*' /tmp/tg_response.json | head -n1 | grep -o '[0-9]*')

    if [[ -n "$TG_CHAT_ID" ]]; then
        echo -e "\n✅ Chat ID detectado: \033[1;32m$TG_CHAT_ID\033[0m"
        guardar_config
        enviar_mensaje "🤖 Bot activo y configurado correctamente."
    else
        echo -e "\n❌ No se detectó ningún chat. Asegurate de mandarle un mensaje al bot."
    fi
}

enviar_mensaje() {
    local mensaje="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
         -d "chat_id=${TG_CHAT_ID}&text=${mensaje}" > /dev/null
}

test_mensaje() {
    cargar_config
    if [[ -z "$TG_TOKEN" || -z "$TG_CHAT_ID" ]]; then
        echo "⚠️ Faltan datos de configuración."
    else
        enviar_mensaje "✅ Mensaje de prueba enviado desde tu VPS."
        echo "📬 Mensaje enviado a $TG_CHAT_ID"
    fi
}

# === Menú principal ===
while true; do
    clear
    echo -e "🔧 Configuración Bot Telegram\n"
    echo "1) Detectar Chat ID + Guardar Token"
    echo "2) Enviar mensaje de prueba"
    echo "3) Salir"
    echo -n "#? "
    read -r opt
    case $opt in
        1) detectar_chat_id ;;
        2) test_mensaje ;;
        3) break ;;
        *) echo "❌ Opción inválida"; sleep 1 ;;
    esac
done
