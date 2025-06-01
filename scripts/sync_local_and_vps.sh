#!/usr/bin/env bash
set -euo pipefail


read -p "✏️ Comentario para el commit: " COMENTARIO_COMMIT
export COMENTARIO_COMMIT

notify_error() {
    notify-send "❌ Error de sincronización" "Revisá logs o conexión SSH"
    command -v canberra-gtk-play &>/dev/null && canberra-gtk-play -i dialog-error
    exit 1
}
trap notify_error ERR

echo "🚀 Subiendo cambios a GitHub..."
bash ~/Documentos/GitHub/api_bank_h2/scripts/00_16_01_subir_GitHub.sh

echo "📦 Llamando al VPS para sincronizar..."
ssh -i ~/.ssh/vps_njalla_nueva -p 22 markmur88@80.78.30.242 \
"bash ~/api_bank_heroku/scripts/00_24_sync_from_github.sh"

notify-send "✅ Despliegue completo" "Código actualizado en GitHub y sincronizado con el VPS"
command -v canberra-gtk-play &>/dev/null && canberra-gtk-play -i complete



