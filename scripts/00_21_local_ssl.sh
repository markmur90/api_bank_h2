#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Activando entorno virtual..."
source "$HOME/Documentos/Entorno/envAPP/bin/activate"

PROJECT_DIR="$HOME/Documentos/GitHub/api_bank_h2"
cd "$PROJECT_DIR"

CERT_CRT="certs/desarrollo.crt"
CERT_KEY="certs/desarrollo.key"

if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "⚠️ Certificados no encontrados. Generando nuevos..."
    mkdir -p certs
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=Local Dev/OU=Dev/CN=localhost"
fi

if sudo lsof -i :8443 | grep -q LISTEN; then
    echo "🧅 Puerto 8443 ya está en uso (probablemente Nginx)."
    
    if sudo lsof -i :8000 | grep -q LISTEN; then
        echo "⚠️ Puerto 8000 en uso. Liberando..."
        sudo fuser -k 8000/tcp
        sleep 2
    fi

    echo "🚀 Ejecutando Gunicorn como backend en http://0.0.0.0:8000"
    gunicorn config.wsgi:application --bind 0.0.0.0:8000
else
    echo "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443"
    echo "🔐 Certificado: $CERT_CRT"
    gunicorn config.wsgi:application \
      --certfile="$CERT_CRT" \
      --keyfile="$CERT_KEY" \
      --bind 0.0.0.0:8443
fi
