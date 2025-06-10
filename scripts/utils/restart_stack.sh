#!/bin/bash
set -euo pipefail

APP_DIR="/home/markmur88/api_bank_heroku"
SOCK_PATH="$APP_DIR/api.sock"
SUPERVISOR_PROGRAM="coretransapi"

echo "🔁 Reiniciando Gunicorn a través de Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart "$SUPERVISOR_PROGRAM"

echo "⏳ Esperando que Gunicorn cree el socket..."
for i in {1..10}; do
  if [[ -S "$SOCK_PATH" ]]; then
    echo "✅ Socket encontrado en $SOCK_PATH"
    break
  fi
  sleep 1
done

if [[ ! -S "$SOCK_PATH" ]]; then
  echo "❌ El socket no fue generado. Verificá logs de Gunicorn."
  exit 1
fi

echo "🔐 Ajustando permisos del socket..."
sudo chown markmur88:www-data "$SOCK_PATH"
sudo chmod 770 "$SOCK_PATH"

echo "🔄 Reiniciando Nginx..."
sudo systemctl restart nginx

echo "✅ Stack reiniciado correctamente."
