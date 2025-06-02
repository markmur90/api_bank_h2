#!/bin/bash

echo "🚀 Iniciando despliegue de Ghost Recon..."

PROJECT_DIR=$(pwd)
ENV_FILE=".env"
COMPOSE_FILE="docker-compose.prod.yml"
DOMAIN="yourdomain.com"

# Verificar .env
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Archivo .env no encontrado. Crea uno primero."
    exit 1
fi

# Construcción
echo "🔧 Construyendo imágenes..."
docker-compose -f $COMPOSE_FILE build || { echo "❌ Falló la construcción"; exit 1; }

# Primer arranque (para certbot)
echo "🌐 Iniciando servicios..."
docker-compose -f $COMPOSE_FILE up -d nginx db web

# Espera para asegurarse de que nginx sirva .well-known
sleep 10

# Solicitar certificados SSL
echo "🔐 Obteniendo certificado SSL con Certbot para $DOMAIN..."
docker-compose -f $COMPOSE_FILE run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@$DOMAIN \
  --agree-tos \
  --no-eff-email \
  -d $DOMAIN -d www.$DOMAIN

# Reiniciar Nginx con certificados
echo "♻️ Reiniciando Nginx con certificados SSL..."
docker-compose -f $COMPOSE_FILE restart nginx

# Recolectar archivos estáticos
echo "📦 Recolectando archivos estáticos..."
docker-compose -f $COMPOSE_FILE exec web python manage.py collectstatic --noinput

# Mostrar logs
echo "📋 Logs en vivo (Ctrl+C para salir):"
docker-compose -f $COMPOSE_FILE logs -f web
