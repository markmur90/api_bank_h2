#!/usr/bin/env bash
set -euo pipefail




echo "🚀 Desplegando coretransapi en VPS..."

# 1. Configuración de Supervisor para Gunicorn
echo "⚙️  Creando configuración de Supervisor..."
sudo tee /etc/supervisor/conf.d/coretransapi.conf > /dev/null <<SUPERVISOR
[program:coretransapi]
directory=/home/markmur88/api_bank_heroku
command=/home/markmur88/envAPP/bin/gunicorn config.wsgi:application \
    --bind unix:/home/markmur88/api_bank_heroku/api.sock \
    --workers 3
autostart=true
autorestart=true

# Umask para que el socket sea accesible por grupo (www-data)
umask=007

stderr_logfile=/var/log/supervisor/coretransapi.err.log
stdout_logfile=/var/log/supervisor/coretransapi.out.log

user=markmur88
group=www-data

# Variables de entorno necesarias para Django
environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="config.settings",\
  DJANGO_ENV="production"
SUPERVISOR

echo "🔄 Recargando Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start coretransapi

# 2. Configuración Nginx
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<NGINX
server {
    listen 80;
    server_name api.coretransapi.com;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    ssl_certificate /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;

    location /static/ {
        alias /home/markmur88/api_bank_heroku/static/;
    }

    location /media/ {
        alias /home/markmur88/api_bank_heroku/media/;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/markmur88/api_bank_heroku/api.sock;
    }
}
NGINX

echo "🔗 Habilitando sitio en Nginx..."
sudo ln -sf /etc/nginx/sites-available/coretransapi.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# 3. Verificar que el dominio apunte aquí
echo "🔍 Verificando DNS..."
VPS_IPV4=\$(hostname -I | awk '{print \$1}')
DNS_IP=\$(dig +short api.coretransapi.com | grep -Eo '([0-9]{1,3}\\.){3}[0-9]{1,3}' | head -n1 || true)

if [[ -z "\$DNS_IP" ]]; then
    echo "❌ No se obtuvo IP de DNS para api.coretransapi.com. Abortando."
    exit 1
fi

if [[ "\$DNS_IP" != "\$VPS_IPV4" ]]; then
    echo "❌ DNS (\$DNS_IP) no coincide con IP local (\$VPS_IPV4). Abortando Certbot."
    exit 1
fi

# 4. Solicitar/renovar certificado SSL
echo "🔐 Solicitando certificado SSL con Let's Encrypt..."
sudo certbot --nginx \
    -d api.coretransapi.com \
    --non-interactive \
    --agree-tos \
    -m netghostx90@protonmail.com \
    --redirect

# 5. Recargar Nginx
echo "🔄 Probando configuración Nginx..."
sudo nginx -t
echo "✅ Configuración OK, reload Nginx..."
sudo systemctl reload nginx

# 6. Activar Fail2Ban
echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now

echo "🎉 Despliegue completado exitosamente."
