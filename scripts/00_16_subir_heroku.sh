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

COMENTARIO_COMMIT="${COMENTARIO_COMMIT:-Actualización automática $(date '+%Y-%m-%d %H:%M:%S')}"

{
  echo ""
  echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
  echo -e "📄 Script: $SCRIPT_NAME"
  echo -e "═══════════════════════════════════════════"
} | tee -a "$LOG_FILE" "$LOG_DEPLOY"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE" "$LOG_DEPLOY"; exit 1' ERR

# === Validación de Heroku CLI ===
command -v heroku >/dev/null || { echo "❌ Heroku CLI no está instalado." | tee -a "$LOG_DEPLOY"; exit 1; }

# === Desactivamos collectstatic ===
echo -e "\n🔧 Desactivando collectstatic en Heroku..." | tee -a "$LOG_DEPLOY"
heroku config:set DISABLE_COLLECTSTATIC=1 --app "$HEROKU_APP"

heroku config:set DEBUG=False --app "$HEROKU_APP"
heroku config:set ALLOWED_HOSTS="apibank2-54644cdf263f.herokuapp.com" --app "$HEROKU_APP"

heroku config:set SECRET_KEY="MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw" --app "$HEROKU_APP"
heroku config:set DJANGO_ENV=production --app "$HEROKU_APP"
heroku config:set ENVIRONMENT=production --app "$HEROKU_APP"



# === Carga de variables desde .env.production ===
# echo -e "\n📤 Cargando variables desde $ENV_FILE..." | tee -a "$LOG_DEPLOY"
# [[ -f "$ENV_FILE" ]] || { echo "❌ Archivo $ENV_FILE no encontrado." | tee -a "$LOG_DEPLOY"; exit 1; }

# success=0
# while IFS='=' read -r key value; do
#   [[ -z "${key// }" || "${key:0:1}" == "#" ]] && continue
#   value="${value%\"}"
#   value="${value#\"}"
#   if heroku config:set "$key=$value" --app "$HEROKU_APP" >> "$LOG_DEPLOY" 2>&1; then
#     echo "✅ $key cargada correctamente" | tee -a "$LOG_DEPLOY"
#   else
#     echo "⚠️  Error al cargar $key" | tee -a "$LOG_DEPLOY"
#   fi
# done < "$ENV_FILE"

# === Subida de clave privada codificada ===
if [[ -f "$PEM_PATH" ]]; then
  echo -e "\n🔑 Clave privada detectada en $PEM_PATH" | tee -a "$LOG_DEPLOY"
  PRIVATE_KEY_B64=$(base64 -w 0 "$PEM_PATH")
  if heroku config:set PRIVATE_KEY_B64="$PRIVATE_KEY_B64" --app "$HEROKU_APP" >> "$LOG_DEPLOY" 2>&1; then
    echo "✅ Clave privada codificada subida como PRIVATE_KEY_B64" | tee -a "$LOG_DEPLOY"
  else
    echo "⚠️  Error al subir PRIVATE_KEY_B64" | tee -a "$LOG_DEPLOY"
  fi
else
  echo "⚠️  Archivo $PEM_PATH no encontrado. Saltando PRIVATE_KEY_B64." | tee -a "$LOG_DEPLOY"
fi

# === Push a GitHub y Heroku ===
echo -e "\n🚀 Subiendo el proyecto a Heroku y GitHub...\n" | tee -a "$LOG_DEPLOY"
cd "$HEROKU_ROOT" || { echo "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

echo -e "📦 Haciendo git add..." | tee -a "$LOG_DEPLOY"
git add --all

echo -e "📝 Commit con mensaje: $COMENTARIO_COMMIT" | tee -a "$LOG_DEPLOY"
git commit -m "$COMENTARIO_COMMIT" || echo "ℹ️  Sin cambios para commitear." | tee -a "$LOG_DEPLOY"

echo -e "🌐 Push a GitHub..." | tee -a "$LOG_DEPLOY"
git push origin api-bank || { echo "❌ Error al subir a GitHub"; exit 1; }

sleep 3
export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
echo "$HEROKU_API_KEY" | heroku auth:token | tee -a "$LOG_DEPLOY"

echo -e "☁️  Push a Heroku..." | tee -a "$LOG_DEPLOY"
git push heroku api-bank:main || { echo "❌ Error en deploy a Heroku"; exit 1; }

sleep 3
heroku restart --app "$HEROKU_APP" | tee -a "$LOG_DEPLOY"
echo -e "✅ Heroku reiniciado correctamente." | tee -a "$LOG_DEPLOY"

cd "$PROJECT_ROOT"
echo -e "\n🎉 ✅ ¡Deploy completado con éxito!" | tee -a "$LOG_DEPLOY"
