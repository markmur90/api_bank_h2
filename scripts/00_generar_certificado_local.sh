#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

echo -e "\033[1;36m🔐 Generando certificado SSL local autofirmado...\033[0m"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"

CERT_DIR="./certs"
CERT_KEY="$CERT_DIR/desarrollo.key"
CERT_CRT="$CERT_DIR/desarrollo.crt"

mkdir -p "$CERT_DIR"

SUBJECT="/C=ES/ST=Local/L=Localhost/O=Desarrollo/OU=Django/CN=localhost"

openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
    -keyout "$CERT_KEY" \
    -out "$CERT_CRT" \
    -subj "$SUBJECT" \
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo -e "\n\033[1;32m✅ Certificado generado en:\033[0m"
echo -e "   📄 Clave privada: \033[1;33m$CERT_KEY\033[0m"
echo -e "   📄 Certificado  : \033[1;33m$CERT_CRT\033[0m"

echo -e "\n\033[1;36m🌐 Para usarlo en django-sslserver:\033[0m"
echo -e "   python manage.py runsslserver --certificate $CERT_CRT --key $CERT_KEY"

echo -e "\n\033[1;34m🧠 Consejo:\033[0m Abre https://127.0.0.1:8000 en tu navegador y acepta el riesgo para continuar.\n"
