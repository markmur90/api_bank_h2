#!/bin/bash

echo "🚀 Aplicando optimizaciones de rendimiento..."

# 1. Crear directorios de logs si no existen
mkdir -p /home/markmur88/api_bank_h2/logs
mkdir -p /home/markmur88/api_bank_h2/staticfiles

# 2. Recolectar archivos estáticos
cd /home/markmur88/api_bank_h2
source /home/markmur88/envSIM/bin/activate
python manage.py collectstatic --noinput

# 3. Aplicar migraciones
python manage.py migrate --noinput

# 4. Reiniciar servicios
sudo systemctl daemon-reload
sudo systemctl restart api_bank_h2
sudo systemctl restart nginx

# 5. Verificar estado
echo "📊 Estado de servicios:"
sudo systemctl status api_bank_h2 --no-pager
sudo systemctl status nginx --no-pager

# 6. Verificar configuración de Nginx
echo "🔍 Verificando configuración de Nginx:"
sudo nginx -t

# 7. Mostrar logs recientes
echo "📝 Últimos logs de Gunicorn:"
tail -n 10 /home/markmur88/api_bank_h2/logs/gunicorn_error.log

echo "✅ Optimizaciones aplicadas correctamente"
echo "🌐 Tu aplicación debería estar más rápida ahora"