#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DEPLOY="$SCRIPT_DIR/logs/despliegue/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_DEPLOY)"


cd "$PROJECT_ROOT"
source "$VENV_PATH/bin/activate"
echo "🧹 Eliminando cachés de Python y migraciones anteriores..." | tee -a $LOG_DEPLOY
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo "🔄 Generando migraciones de Django..." | tee -a $LOG_DEPLOY
python manage.py makemigrations
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo "⏳ Aplicando migraciones de la base de datos..." | tee -a $LOG_DEPLOY
python manage.py migrate
echo "⏳ Migraciones a la base de datos completa." | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
echo "⏳ Aplicando Collectstatic..." | tee -a $LOG_DEPLOY
python manage.py collectstatic --noinput
echo "⏳ Migraciones a la base de datos completa." | tee -a $LOG_DEPLOY
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m" | tee -a $LOG_DEPLOY
echo "" | tee -a $LOG_DEPLOY
