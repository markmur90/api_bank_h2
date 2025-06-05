#!/bin/bash

echo "🌐 Configurando Ghost Recon PÚBLICO (IP pública)..."

sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "/etc/ssl/bank_ghost/ghost.key" \
  -out "/etc/ssl/bank_ghost/ghost.crt" \
  -subj "/C=US/ST=None/L=None/O=GhostRecon/CN=$(hostname -I | awk '{print $1}')"

NGINX_CONF="/etc/nginx/sites-available/bank_ghost_public"
IP_PUBLICA=$(hostname -I | awk '{print $1}')

sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate     /etc/ssl/bank_ghost/ghost.crt;
    ssl_certificate_key /etc/ssl/bank_ghost/ghost.key;

    location /static/ {
        alias /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/staticfiles/;
    }

    location /media/ {
        alias /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/media/;
    }

    location /ghostrecon/ {
        proxy_pass http://0.0.0.0:8011/ghostrecon/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/logs/nginx_access.log;
    error_log  /home/markmur88/Documentos/GitHub/zIncognito/bank_ghost/logs/nginx_error.log;
}

server {
    listen 80;
    return 301 https://$host$request_uri;
}
EOF

sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/"
sudo systemctl restart nginx

echo "✅ Ghost Recon PÚBLICO disponible en: https://$IP_PUBLICA/ghostrecon/dashboard/"
