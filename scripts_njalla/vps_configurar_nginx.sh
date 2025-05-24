#!/bin/bash
set -e

echo "🌐 Configuración de Nginx..."
cp /root/api_bank_heroku/nginx.conf /etc/nginx/sites-available/api_bank_heroku.conf
ln -sf /etc/nginx/sites-available/api_bank_heroku.conf /etc/nginx/sites-enabled/api_bank_heroku.conf
rm -f /etc/nginx/sites-enabled/default

echo "🔐 Certificado SSL..."
certbot --nginx -d api.coretransapi.com --non-interactive --agree-tos -m admin@coretransapi.com --redirect

echo "🔄 Reiniciando Nginx..."
nginx -t && systemctl reload nginx
