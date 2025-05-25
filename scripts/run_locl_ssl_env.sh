#!/usr/bin/env bash
set -euo pipefail

CERT_CRT="certs/desarrollo.crt"
CERT_KEY="certs/desarrollo.key"
GUNICORN_PORT=8000
SSL_PORT=8443

echo -e "\033[1;36m🔐 Verificando certificado autofirmado...\033[0m"
if [[ ! -f "$CERT_CRT" || ! -f "$CERT_KEY" ]]; then
    echo -e "\033[1;33m📄 No existe el certificado. Generando...\033[0m"
    bash ./scripts/00_generar_certificado_local.sh
else
    echo -e "\033[1;32m✅ Certificado existente.\033[0m"
fi

echo -e "\n\033[1;36m🚀 Lanzando Gunicorn en background...\033[0m"
pkill -f "gunicorn.*$GUNICORN_PORT" 2>/dev/null || true
nohup gunicorn config.wsgi:application --bind 127.0.0.1:$GUNICORN_PORT > logs/gunicorn_local.log 2>&1 &

sleep 2

echo -e "\n\033[1;36m🧪 Verificando Nginx y sitio local SSL en puerto $SSL_PORT...\033[0m"
NGINX_STATUS=$(curl -skI https://localhost:$SSL_PORT | grep HTTP || true)
if [[ "$NGINX_STATUS" == *"200"* ]]; then
    echo -e "\033[1;32m✅ Nginx responde correctamente en https://localhost:$SSL_PORT\033[0m"
else
    echo -e "\033[1;31m❌ Nginx no responde en https://localhost:$SSL_PORT\033[0m"
    echo -e "\033[1;33m⚠ Revisa que el sitio 'django_local_ssl' esté habilitado y que Nginx haya sido reiniciado\033[0m"
    exit 1
fi

echo -e "\n\033[1;36m🌐 Abriendo navegador en https://localhost:$SSL_PORT...\033[0m"
xdg-open https://localhost:$SSL_PORT || open https://localhost:$SSL_PORT || true

echo -e "\n\033[1;32m🎉 Entorno local con SSL iniciado con éxito.\033[0m"
