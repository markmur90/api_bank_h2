#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_$(date +%Y%m%d_%H%M).log"
mkdir -p "$(dirname $LOG_DEPLOY)"


PROJECT_ROOT="$HOME/Documentos/GitHub/api_bank_h2"

HEROKU_ROOT="$HOME/Documentos/GitHub/api_bank_heroku"

echo -e "\033[7;30m🚀 Subiendo el proyecto a Heroku y GitHub...\033[0m" | tee -a $LOG_DEPLOY
cd "$HEROKU_ROOT" || { echo -e "\033[7;30m❌ Error al acceder a "$HEROKU_ROOT"\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY

echo -e "\033[7;30mHaciendo git add...\033[0m" | tee -a $LOG_DEPLOY
git add --all
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo -e "\033[7;30mHaciendo commit con el mensaje: \"$COMENTARIO_COMMIT\"...\033[0m" | tee -a $LOG_DEPLOY
git commit -m "$COMENTARIO_COMMIT"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo -e "\033[7;30mHaciendo push a GitHub...\033[0m" | tee -a $LOG_DEPLOY
git push origin api-bank || { echo -e "\033[7;30m❌ Error al subir a GitHub\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
sleep 3
export HEROKU_API_KEY="HRKU-6803f1ea-fd1f-4210-a5cd-95ca7902ccf6"
echo "$HEROKU_API_KEY" | heroku auth:token | tee -a $LOG_DEPLOY
echo -e "\033[7;30mHaciendo push a Heroku...\033[0m" | tee -a $LOG_DEPLOY
git push heroku api-bank:main || { echo -e "\033[7;30m❌ Error en deploy\033[0m"; exit 0; }
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
sleep 3
cd "$PROJECT_ROOT"
echo -e "\033[7;30m✅ ¡Deploy completado!\033[0m" | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
