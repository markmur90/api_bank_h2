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



echo -e "\n🚀 Subiendo el proyecto a Heroku y GitHub..."
cd "$HEROKU_ROOT" || { echo "❌ Error al acceder a $HEROKU_ROOT"; exit 1; }

git rm -r --cached .

echo -e "📦 Haciendo git add..."
git add --all

echo -e "📝 Commit con mensaje: $COMENTARIO_COMMIT"
git commit -m "$COMENTARIO_COMMIT" || echo "ℹ️  Sin cambios para commitear."

echo -e "🌐 Push a GitHub..."
git push origin api-bank || { echo "❌ Error al subir a GitHub"; exit 1; }


cd "$PROJECT_ROOT"
echo -e "\n🎉 ✅ ¡Puss a GitHub completo!"
