#!/bin/bash

# === CONFIGURACIÓN GENERAL ===
PROJECT_DIR="/home/markmur88/Documentos/GitHub/zIncognito/bank_ghost"
MANAGE="$PROJECT_DIR/manage.py"
KEYS_DIR="$PROJECT_DIR/schemas/keys"
KEY_PATH="$KEYS_DIR/private_key.pem"

# === DETECTA EL ENTORNO DESEADO ===
ENVIRONMENT=${1:-local}
echo "🌍 Entorno seleccionado: $ENVIRONMENT"

# === ARCHIVO .env CORRESPONDIENTE ===
ENV_FILE="$PROJECT_DIR/.env.$ENVIRONMENT"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ Archivo de entorno no encontrado: $ENV_FILE"
  exit 1
fi

# === VALIDACIÓN DE LA CLAVE PRIVADA ===
if [ ! -f "$KEY_PATH" ]; then
  echo "🔐 Clave privada no encontrada en: $KEY_PATH"
  exit 1
fi

# === EXPORTA VARIABLES DE ENTORNO ===
echo "📦 Cargando variables desde $ENV_FILE"
export DJANGO_ENV=$ENVIRONMENT
export PRIVATE_KEY_PATH="$KEY_PATH"
set -o allexport
source "$ENV_FILE"
set +o allexport

# === ACCIONES POR ENTORNO ===
case "$ENVIRONMENT" in

  local)
    echo "🚀 Entorno local (con Nginx): aplicando migraciones y ejecutando servidor..."
    python "$MANAGE" migrate
    python "$MANAGE" runserver 0.0.0.0:8000
    ;;

  sandbox)
    echo "🧪 Entorno sandbox: migraciones y servidor de pruebas..."
    python "$MANAGE" migrate
    python "$MANAGE" runserver 0.0.0.0:8001
    ;;

  production|web)
    echo "🔒 Producción (web.com): activando entorno virtual y reiniciando servicios..."
    source /var/www/bank_ghost/venv/bin/activate
    python "$MANAGE" migrate
    sudo systemctl restart gunicorn
    ;;

  heroku)
    echo "☁️ Heroku: push y configuración remota..."
    heroku config:set DJANGO_ENV=heroku PRIVATE_KEY_PATH="$KEY_PATH"
    git push heroku main
    ;;

  *)
    echo "❓ Entorno desconocido: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "✅ Script finalizado con éxito para entorno [$ENVIRONMENT]"
