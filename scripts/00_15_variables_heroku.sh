#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
ENV_FILE="$PROJECT_ROOT/.env.production"
HEROKU_APP="${1:-apibank2}"
PEM_PATH="$HOME/Documentos/GitHub/api_bank_h2/schemas/keys/private_key.pem"

LOG_FILE="$SCRIPT_DIR/logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/${SCRIPT_NAME%.sh}.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═════════════════════════════════════════════════════════════"
  echo -e "🚀 Subiendo variables de entorno a Heroku ($HEROKU_APP)..."
} | tee -a "$LOG_FILE" "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE" "$LOG_DEPLOY"; exit 1' ERR

command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado." | tee -a "$LOG_DEPLOY"; exit 1; }

# === Desactivamos collectstatic para evitar errores innecesarios en producción ===
echo -e "\n🔧 Desactivando collectstatic en Heroku..." | tee -a "$LOG_DEPLOY"
heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"

# === Carga de variables desde el archivo .env.production ===
echo -e "\n📤 Cargando variables desde $ENV_FILE..." | tee -a "$LOG_DEPLOY"
[[ -f "$ENV_FILE" ]] || { echo "❌ Archivo $ENV_FILE no encontrado." | tee -a "$LOG_DEPLOY"; exit 1; }

success=0
while IFS='=' read -r key value; do
  [[ -z "${key// }" || "${key:0:1}" == "#" ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  if heroku config:set "$key=$value" --app "$HEROKU_APP" >> "$LOG_DEPLOY" 2>&1; then
    echo "✅ $key cargada correctamente" | tee -a "$LOG_DEPLOY"
    ((success++))
  else
    echo "⚠️  Error al cargar $key" | tee -a "$LOG_DEPLOY"
  fi
done < "$ENV_FILE"

# === Subida de clave privada codificada ===
if [[ -f "$PEM_PATH" ]]; then
  echo -e "\n🔑 Clave privada detectada en $PEM_PATH" | tee -a "$LOG_DEPLOY"
  PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
  if heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP" >> "$LOG_DEPLOY" 2>&1; then
    echo "✅ Clave privada codificada subida como PRIVATE_KEY_B64" | tee -a "$LOG_DEPLOY"
    ((success++))
  else
    echo "⚠️  Error al subir PRIVATE_KEY_B64" | tee -a "$LOG_DEPLOY"
  fi
else
  echo "⚠️  Archivo $PEM_PATH no encontrado. Saltando PRIVATE_KEY_B64." | tee -a "$LOG_DEPLOY"
fi

echo -e "\n📦 Total de variables cargadas: $success" | tee -a "$LOG_DEPLOY"
echo -e "✅ Finalizado correctamente.\n" | tee -a "$LOG_DEPLOY"
