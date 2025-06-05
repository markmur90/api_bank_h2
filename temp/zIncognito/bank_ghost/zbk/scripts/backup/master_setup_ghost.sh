#!/bin/bash

echo "🔧 Setup Maestro para Ghost Recon (HTTPS con NGINX)"

read -p "Selecciona modo (local/público): " MODO
MODO=$(echo "$MODO" | tr '[:upper:]' '[:lower:]')

if [[ "$MODO" == "local" ]]; then
    echo "✅ Ejecutando modo LOCAL..."
    bash ./setup_ghost_local.sh
elif [[ "$MODO" == "público" || "$MODO" == "publico" || "$MODO" == "public" ]]; then
    echo "🌐 Ejecutando modo PÚBLICO..."
    bash ./setup_ghost_public.sh
else
    echo "❌ Modo no reconocido. Usa 'local' o 'público'."
    exit 1
fi
