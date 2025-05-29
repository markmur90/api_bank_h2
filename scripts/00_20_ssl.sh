#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/logs/01_full_deploy/${SCRIPT_NAME%.sh}.log"
PROCESS_LOG="$SCRIPT_DIR/logs/01_full_deploy/process_ssl.log"

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$PROCESS_LOG")"

# Limpiar log de proceso
> "$PROCESS_LOG"

{
  echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "📄 Script: $SCRIPT_NAME"
  echo "═════════════════════════════════════════════════════════════"
} >> "$LOG_FILE"
{
  echo "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "📄 Script: $SCRIPT_NAME"
  echo "═════════════════════════════════════════════════════════════"
} >> "$PROCESS_LOG"

trap '{
  echo "";
  echo "❌ Error en línea $LINENO: \"$BASH_COMMAND\"";
  echo "Abortando ejecución.";
} >> "$LOG_FILE" >> "$PROCESS_LOG"; exit 1' ERR

{
#   echo "🔐 Activando entorno virtual..."
#   source "$SCRIPT_DIR/../../venv/bin/activate"

  PROJECT_DIR="$HOME/Documentos/GitHub/api_bank_h2"
  cd "$PROJECT_DIR"

  CERT_DIR="$PROJECT_DIR/certs"
  CERT_KEY="$CERT_DIR/desarrollo.key"
  CERT_CRT="$CERT_DIR/desarrollo.crt"

  if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo "❌ Certificado no encontrado: $CERT_CRT o $CERT_KEY"
    exit 1
  fi

  echo "🌐 Levantando entorno local con Gunicorn + SSL en https://0.0.0.0:8443"

  cd "$SCRIPT_DIR/.." || exit 1

  nohup gunicorn config.wsgi:application \
    --certfile="$CERT_CRT" \
    --keyfile="$CERT_KEY" \
    --bind 0.0.0.0:8443 \
    --workers 3 \
    --timeout 300 \
    --log-file - >> "$PROCESS_LOG" 2>&1 &
} >> "$PROCESS_LOG" 2>&1
