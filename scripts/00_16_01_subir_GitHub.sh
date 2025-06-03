#!/usr/bin/env bash
set -euo pipefail

: "${COMENTARIO_COMMIT:?❌ Faltó COMENTARIO_COMMIT}"

SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$HOME/api_bank_h2"
HEROKU_ROOT="$HOME/api_bank_heroku"
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
git push -u origin api-bank || { echo "❌ Error al subir a GitHub"; exit 1; }

# 📝 Guardar histórico en formato Markdown
COMMIT_LOG="$SCRIPT_DIR/logs/commits_hist.md"
mkdir -p "$(dirname "$COMMIT_LOG")"

# Agregar encabezado si el archivo está vacío o no existe
if [ ! -s "$COMMIT_LOG" ]; then
    echo -e "| Fecha                | Mensaje de commit                          |\n|----------------------|----------------------------------------------|" > "$COMMIT_LOG"
fi

# Añadir entrada nueva
echo "| $(date '+%Y-%m-%d %H:%M:%S') | ${COMENTARIO_COMMIT//|/–} |" >> "$COMMIT_LOG"



cd "$PROJECT_ROOT"
echo -e "\n🎉 ✅ ¡Puss a GitHub completo!"
