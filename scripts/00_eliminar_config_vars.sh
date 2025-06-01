#!/bin/bash

# Nombre de la app Heroku
APP_NAME="apibank2"

# Obtener todas las claves de configuración
CONFIG_VARS=$(heroku config --app "$APP_NAME" --json | jq -r 'keys[]')

# Confirmar acción destructiva
echo "⚠ Esto eliminará TODAS las config vars de Heroku para $APP_NAME"
read -p "¿Estás seguro? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "❌ Operación cancelada"
  exit 1
fi

# Borrado en bucle
for var in $CONFIG_VARS; do
  echo "Eliminando $var..."
  heroku config:unset "$var" --app "$APP_NAME"
done

echo "✅ Todas las variables han sido eliminadas."
