#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/${SCRIPT_NAME%.sh}_.log"
LOG_DETALLE="./scripts/logs/00_20_ssl_detalle.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOG_DETALLE")"

# Cabecera solo en el log maestro
{
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} >> "$LOG_FILE"

# Redirigir salida detallada a log de proceso
exec > >(tee -a "$LOG_DETALLE") 2>&1

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_DETALLE"; exit 1' ERR

echo -e "🔐 Activando entorno virtual..."
# source ./venv/bin/activate

CERT_CRT="./schemas/certs/desarrollo.crt"
CERT_KEY="./schemas/certs/desarrollo.key"

echo -e "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443"
gunicorn api.wsgi:application \
    --certfile="$CERT_CRT" \
    --keyfile="$CERT_KEY" \
    --bind 0.0.0.0:8443 \
    --log-level=debug

echo -e "\n\033[1;34m🧠 Consejo:\033[0m Abre https://0.0.0.0:8000 en tu navegador y acepta el riesgo para continuar.\n" | tee -a $LOG_DEPLOY
