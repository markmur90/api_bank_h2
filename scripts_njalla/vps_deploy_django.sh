#!/bin/bash
set -e

echo "📥 Clonando proyecto..."
cd /root
git clone git@github.com:markmur88/api_bank_heroku.git

echo "🐍 Entorno virtual..."
python3 -m venv /root/venvAPI
source /root/venvAPI/bin/activate
pip install --upgrade pip
pip install -r /root/api_bank_heroku/requirements.txt

echo "🛠️ Base de datos PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE bankdb;"
sudo -u postgres psql -c "CREATE USER bankuser WITH PASSWORD 'Ptf8454Jd55';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bankdb TO bankuser;"

echo "⚙️ Django: migrate + static"
cd /root/api_bank_heroku
source /root/venvAPI/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
