#!/bin/bash

echo "🔧 Iniciando despliegue de Ghost Recon..."

# Ruta del proyecto
PROYECTO="bank_ghost"
APP="reconocimiento"
PYTHON=$(which python3)

# echo "📁 Creando entorno virtual..."
# python3 -m venv venv
# source venv/bin/activate
# pip install --upgrade pip

echo "📦 Instalando dependencias..."
pip install django weasyprint playwright requests
playwright install firefox

echo "🐿 Instalando Tor y dependencias del sistema..."
sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
sudo apt install -y tor curl libpango-1.0-0 libgdk-pixbuf2.0-0 libffi-dev libssl-dev build-essential

echo "🔧 Configurando Tor..."
sudo sed -i '/^ControlPort/c\ControlPort 9051' /etc/tor/torrc
sudo sed -i '/^CookieAuthentication/c\CookieAuthentication 1' /etc/tor/torrc
sudo systemctl restart tor

# echo "🌱 Creando app Django si no existe..."
# cd $PROYECTO
# if [ ! -d "$APP" ]; then
#     python manage.py startapp $APP
# fi

# echo "⚙️ Aplicando migraciones..."
# python manage.py makemigrations
# python manage.py migrate

# echo "👤 Creando superusuario (usa admin/admin si lo automatizas)..."
# python manage.py createsuperuser

# echo "📑 Configurando tareas CRON..."
# (crontab -l 2>/dev/null; echo "5 * * * * /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/venv/bin/python3 /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/cron_wrapper.py") | crontab -


echo "✅ Ghost Recon listo. Accede a http://0.0.0.0:8011/ghostrecon/dashboard/"