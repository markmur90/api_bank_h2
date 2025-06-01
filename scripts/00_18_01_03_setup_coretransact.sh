#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------
#  Varible fija con la IP pública del VPS
# ------------------------------------
IP_VPS="80.78.30.242"

echo "🚀 Desplegando coretransapi en VPS (IP_VPS=$IP_VPS)..."

# ----------------------------
# 1. Configuración de Supervisor para Gunicorn
# ----------------------------
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

# Variables de entorno necesarias para Django y la API bancaria
environment=\
  PATH="/home/markmur88/envAPP/bin",\
  DJANGO_SETTINGS_MODULE="config.settings",\
  DJANGO_ENV="production",\
  DEBUG="False",\
  ALLOWED_HOSTS="api.coretransapi.com",\
  SECRET_KEY="MX2QfdeWkTc8ihotA_i1Hm7_4gYJQB4oVjOKFnuD6Cw",\
  REDIRECT_URI="https://api.coretransapi.com/oauth2/callback/",\
  ORIGIN="https://api.coretransapi.com",\
  CLIENT_ID="7c1e2c53-8cc3-4ea0-bdd6-b3423e76adc7",\
  CLIENT_SECRET="L88pwGelUZ5EV1YpfOG3e_r24M8YQ40-Gaay9HC4vt4RIl-Jz2QjtmcKxY8UpOWUInj9CoUILPBSF-H0QvUQqw",\
  TOKEN_URL="https://simulator-api.db.com:443/gw/oidc/token",\
  AUTHORIZE_URL="https://simulator-api.db.com:443/gw/oidc/authorize",\
  OTP_URL="https://simulator-api.db.com:443/gw/dbapi/others/onetimepasswords/v2/single",\
  AUTH_URL="https://simulator-api.db.com:443/gw/dbapi/others/transactionAuthorization/v1/challenges",\
  API_URL="https://simulator-api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer",\
  SCOPE="sepa_credit_transfers",\
  TIMEOUT="3600",\
  TIMEOUT_REQUEST="3600"
SUPERVISOR

echo "🔄 Recargando Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update

# Si ya estaba arrancado, reiniciamos; si no, lo arrancamos
if sudo supervisorctl status coretransapi | grep -q "RUNNING"; then
    echo "⚠ coretransapi ya estaba arrancado; lo reiniciamos..."
    sudo supervisorctl restart coretransapi
else
    sudo supervisorctl start coretransapi
fi

# ----------------------------
# 2. Configuración Nginx
# ----------------------------
echo "🌐 Configurando Nginx..."
sudo tee /etc/nginx/sites-available/coretransapi.conf > /dev/null <<NGINX
# /etc/nginx/sites-available/coretransapi.conf

server {
    listen 80;
    server_name api.coretransapi.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.coretransapi.com;

    # SSL temporal: Certbot añadirá las directivas completas (incl. options-ssl-nginx.conf y ssl_dhparam)
    ssl_certificate     /etc/letsencrypt/live/api.coretransapi.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.coretransapi.com/privkey.pem;
    # <——– Estas dos líneas se usan tras que Certbot genere los archivos y agregue 'include /etc/letsencrypt/options-ssl-nginx.conf;'
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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

# ----------------------------
# 3. Verificar que el dominio apunte a la IP fija del VPS
# ----------------------------
# echo "🔍 Verificando DNS contra IP_VPS fija ($IP_VPS)..."
# # Obtenemos la primera IPv4 que devuelva `host` para el dominio
# DNS_IP=$(host api.coretransapi.com 2>/dev/null | awk '/has address/ { print $4; exit }' || true)

# if [[ -z "$DNS_IP" ]]; then
#     echo "❌ No se obtuvo IP de DNS para api.coretransapi.com. Abortando."
#     exit 1
# fi

# if [[ "$DNS_IP" != "$IP_VPS" ]]; then
#     echo "❌ DNS ($DNS_IP) no coincide con IP fija del VPS ($IP_VPS). Abortando Certbot."
#     exit 1
# fi

# ----------------------------
# 4. Solicitar/renovar certificado SSL
# ----------------------------
echo "🔐 Solicitando certificado SSL con Let's Encrypt..."
sudo certbot --nginx \
    -d api.coretransapi.com \
    --non-interactive \
    --agree-tos \
    -m admin@coretransapi.com \
    --redirect

# ----------------------------
# 5. Recargar Nginx
# ----------------------------
echo "🔄 Probando configuración Nginx..."
sudo nginx -t
echo "✅ Configuración OK, recargando Nginx..."
sudo systemctl reload nginx

# ----------------------------
# 6. Activar Fail2Ban
# ----------------------------
echo "🧼 Activando Fail2Ban..."
sudo systemctl enable fail2ban --now

echo "🎉 Despliegue completado exitosamente."
