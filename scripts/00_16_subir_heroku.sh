#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"
HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"
ENV_FILE="$PROJECT_ROOT/.env.production"
HEROKU_APP=apibank2
PEM_PATH="$PROJECT_ROOT/schemas/keys/private_key.pem"

LOG_FILE="$SCRIPT_DIR/logs/01_full_deploy/full_deploy.log"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/${SCRIPT_NAME%.sh}.log"
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$LOG_DEPLOY")"

exec > >(tee -a "$LOG_FILE" "$LOG_DEPLOY") 2>&1

echo -e "\n📅 Inicio ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═══════════════════════════════════════════"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución."; exit 1' ERR

# Validación de Heroku CLI
command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado."; exit 1; }

export HEROKU_DEBUG=1
export TERM=dumb


echo -e "\n🔧 Desactivando collectstatic en Heroku..."
# heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP"

echo -e "\n📤 Cargando variables desde $ENV_FILE..."
[[ -f "$ENV_FILE" ]] || { echo "❌ Archivo $ENV_FILE no encontrado."; exit 1; }

HEROKU_DEBUG=1
export TERM=dumb

while IFS='=' read -r key value; do
  [[ -z "${key// }" || "${key:0:1}" == "#" ]] && continue
  value="${value%\"}"
  value="${value#\"}"
  if HEROKU_DEBUG=1 TERM=dumb heroku config:set "$key=$value" --app "$HEROKU_APP" > >(grep -v 'Setting .* restarting' >> "$LOG_DEPLOY") 2>&1; then
    echo "✅ $key cargada correctamente"
  else
    echo "⚠️  Error al cargar $key"
  fi
done < "$ENV_FILE"

if [[ -f "$PEM_PATH" ]]; then
  echo -e "\n🔑 Clave privada detectada en $PEM_PATH"
  PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
  if heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP"; then
    echo "✅ Clave privada codificada subida como PRIVATE_KEY_B64"
  else
    echo "⚠️  Error al subir PRIVATE_KEY_B64"
  fi
else
  echo "⚠️  Archivo $PEM_PATH no encontrado. Saltando PRIVATE_KEY_B64."
fi

echo -e "\n🚀 Subiendo el proyecto a Heroku y GitHub..."
cd "$HEROKU_ROOT" || { echo "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

echo -e "📦 Haciendo git add..."
git add --all

echo -e "📝 Commit con mensaje: $COMENTARIO_COMMIT"
git commit -m "$COMENTARIO_COMMIT" || echo "ℹ️  Sin cambios para commitear."

echo -e "🌐 Push a GitHub..."
git push origin api-bank || { echo "❌ Error al subir a GitHub"; exit 1; }

sleep 3
export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
echo "$HEROKU_API_KEY" | heroku auth:token | tee -a "$LOG_DEPLOY"

echo -e "☁️  Push a Heroku..."
git push heroku api-bank:main || { echo "❌ Error en deploy a Heroku"; exit 1; }

sleep 3
heroku restart --app "$HEROKU_APP"
echo -e "✅ Heroku reiniciado correctamente."

cd "$PROJECT_ROOT"
echo -e "\n🎉 ✅ ¡Deploy completado con éxito!"
