#!/bin/bash
set -e

echo "📥 Clonando proyecto..."
cd /root
git clone git@github.com:markmur88/api_bank_h2.git

echo "🐍 Entorno virtual..."
python3 -m venv /root/envAPP
source /root/envAPP/bin/activate
pip install --upgrade pip
pip install -r /root/api_bank_h2/requirements.txt

echo "🛠️ Base de datos PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE bankdb;"
sudo -u postgres psql -c "CREATE USER bankuser WITH PASSWORD 'Ptf8454Jd55';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bankdb TO bankuser;"

echo "⚙️ Django: migrate + static"
cd /root/api_bank_h2
source /root/envAPP/bin/activate
python manage.py migrate
python manage.py collectstatic --noinput
