#!/usr/bin/env bash
set -euo pipefail

cd "$PROJECT_ROOT"
source "$VENV_PATH/bin/activate"
echo "🧹 Eliminando cachés de Python y migraciones anteriores..."
find . -path "*/__pycache__" -type d -exec rm -rf {} +
find . -name "*.pyc" -delete
find . -path "*/migrations/*.py" -not -name "__init__.py" -delete
find . -path "*/migrations/*.pyc" -delete
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""
echo "🔄 Generando migraciones de Django..."
python manage.py makemigrations
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""    
echo "⏳ Aplicando migraciones de la base de datos..."
python manage.py migrate
echo "⏳ Migraciones a la base de datos completa."
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""    
echo "⏳ Aplicando Collectstatic..."
python manage.py collectstatic --noinput
echo "⏳ Migraciones a la base de datos completa."
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""