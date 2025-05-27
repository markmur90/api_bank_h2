#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
ENV_FILE="$PROJECT_ROOT/.env.production"
PEM_PATH="$HOME/Documentos/GitHub/api_bank_h2/schemas/keys/private_key.pem"
HEROKU_APP="${1:-apibank2}"

LOG_FILE="$SCRIPT_DIR/logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/${SCRIPT_NAME%.sh}.log"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE" "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE" "$LOG_DEPLOY"; exit 1' ERR

command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado." | tee -a "$LOG_DEPLOY"; exit 1; }

echo -e "\033[7;30m🚀 Subiendo variables de entorno a Heroku ($HEROKU_APP)...\033[0m" | tee -a "$LOG_DEPLOY"
cd "$PROJECT_ROOT" || { echo "❌ No se pudo acceder al proyecto en $PROJECT_ROOT" | tee -a "$LOG_DEPLOY"; exit 1; }

heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"

mkdir -p "$(dirname "$PEM_PATH")"
if [[ ! -f "$PEM_PATH" ]]; then
  echo "🔐 Generando nueva clave privada PEM..." | tee -a "$LOG_DEPLOY"
  openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out "$PEM_PATH"
else
  echo "🔑 Clave privada existente detectada en $PEM_PATH" | tee -a "$LOG_DEPLOY"
fi

if base64 --help 2>&1 | grep -q -- '-w'; then
  PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
else
  PRIVATE_KEY_B64=$(base64 "$PEM_PATH" | tr -d '\n')
fi

heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"

# 🔄 Proceso de .env.production
echo -e "\n📤 Cargando variables desde $ENV_FILE...\n" | tee -a "$LOG_DEPLOY"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "❌ No se encontró el archivo: $ENV_FILE" | tee -a "$LOG_DEPLOY"
    exit 1
fi

success=0
fail=0

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    if [[ ! "$line" =~ ^[A-Z0-9_]+=.+$ ]]; then
        echo "⚠️  Formato inválido: $line" | tee -a "$LOG_DEPLOY"
        ((fail++))
        continue
    fi

    if heroku config:set "$line" --app "$HEROKU_APP" >>"$LOG_DEPLOY" 2>&1; then
        echo "✅ OK: $line" | tee -a "$LOG_DEPLOY"
        ((success++))
    else
        echo "❌ Error al aplicar: $line" | tee -a "$LOG_DEPLOY"
        ((fail++))
    fi
done < "$ENV_FILE"

echo -e "\n──────────────────────────────────────────────" | tee -a "$LOG_DEPLOY"
echo "✅ Variables aplicadas con éxito: $success" | tee -a "$LOG_DEPLOY"
echo "❌ Variables con error: $fail" | tee -a "$LOG_DEPLOY"
echo "📋 Log completo: $LOG_DEPLOY" | tee -a "$LOG_DEPLOY"

heroku restart --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"
echo "✅ Heroku reiniciado correctamente." | tee -a "$LOG_DEPLOY"
