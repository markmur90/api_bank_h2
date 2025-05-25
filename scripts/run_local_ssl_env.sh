#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Activando entorno virtual..."
source "$HOME/Documentos/Entorno/venvAPI/bin/activate"

echo "🌍 Estableciendo entorno local HTTPS con certificados autofirmados..."

PROJECT_DIR="$HOME/Documentos/GitHub/api_bank_h2"
cd "$PROJECT_DIR"

CERT_DIR="$PROJECT_DIR/certs"
CERT_CRT="$CERT_DIR/desarrollo.crt"
CERT_KEY="$CERT_DIR/desarrollo.key"

if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "⚠️ Certificados autofirmados no encontrados, generando..."
    mkdir -p "$CERT_DIR"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$CERT_KEY" -out "$CERT_CRT" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=API Bank Dev/OU=IT/CN=localhost"
fi

echo "🚀 Ejecutando Django en modo SSL con runsslserver..."
python manage.py runsslserver --certificate "$CERT_CRT" --key "$CERT_KEY"
