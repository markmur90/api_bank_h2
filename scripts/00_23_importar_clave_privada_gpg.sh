#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_FILE="$PROJECT_DIR/jmoltke_private.asc"
LOG_DEPLOY="$PROJECT_DIR/scripts/logs/despliegue/${SCRIPT_NAME%.sh}.log"

mkdir -p "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_DEPLOY"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "❌ No se encontró el archivo de clave privada: $KEY_FILE" | tee -a "$LOG_DEPLOY"
    exit 1
fi

echo "🔐 Importando clave privada..." | tee -a "$LOG_DEPLOY"
gpg --batch --yes --import "$KEY_FILE"

# Verificar importación
KEY_ID=$(gpg --list-keys --with-colons jmoltke@protonmail.com | grep '^uid:' || true)

if [[ -n "$KEY_ID" ]]; then
  echo "✅ Clave importada correctamente para jmoltke@protonmail.com" | tee -a "$LOG_DEPLOY"
else
  echo "❌ No se pudo importar la clave." | tee -a "$LOG_DEPLOY"
  exit 1
fi

echo -e "\033[7;32m✅ Proceso finalizado.\033[0m" | tee -a "$LOG_DEPLOY"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a "$LOG_DEPLOY"
