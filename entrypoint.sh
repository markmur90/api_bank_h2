#!/bin/bash
set -e

export DJANGO_ENV=sandbox

echo "🚀 Iniciando Django SEPA Bank API"

# Activar entorno virtual si aplica
if [ -d "venv" ]; then
    echo "🔧 Activando entorno virtual..."
    source venv/bin/activate
fi

# Esperar a la base de datos (PostgreSQL)
echo "⏳ Esperando base de datos en $POSTGRES_HOST:$POSTGRES_PORT..."
while ! nc -z "$POSTGRES_HOST" "$POSTGRES_PORT"; do
  sleep 1
done
echo "✅ Base de datos disponible."

# Aplicar migraciones
echo "🗃 Aplicando migraciones..."
python manage.py migrate

# Crear superusuario si no existe
if [ "$CREATE_SUPERUSER" = "true" ]; then
  echo "👑 Verificando superusuario..."
  python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$DJANGO_SUPERUSER_USERNAME').exists():
    User.objects.create_superuser('$DJANGO_SUPERUSER_USERNAME', '$DJANGO_SUPERUSER_EMAIL', '$DJANGO_SUPERUSER_PASSWORD')
EOF
fi

# Realizar backup automático si está habilitado
if [ "$AUTO_BACKUP" = "true" ]; then
  echo "💾 Realizando backup automático..."
  BACKUP_DIR=backups/$(date '+%Y%m%d_%H%M%S')
  mkdir -p "$BACKUP_DIR"
  pg_dump -U "$POSTGRES_USER" -h "$POSTGRES_HOST" "$POSTGRES_DB" > "$BACKUP_DIR/db_backup.sql"
  echo "✅ Backup guardado en $BACKUP_DIR/db_backup.sql"
fi

# Reiniciar honeypot o servicios extra si aplica
if [ -f manage.py ] && grep -q "honeypot" <<< $(python manage.py showmigrations); then
  echo "👁 Reiniciando honeypot..."
  python manage.py runscript honeypot_restart || echo "⚠️ Honeypot no disponible."
fi

# Modo producción o desarrollo
if [ "$DJANGO_PRODUCTION" = "true" ]; then
  echo "🌀 Iniciando Gunicorn..."
  exec gunicorn config.wsgi:application \
      --bind 0.0.0.0:8000 \
      --workers 3 \
      --timeout 90 \
      --log-level info
else
  echo "🌱 Modo desarrollo con runserver..."
  exec python manage.py runserver 0.0.0.0:8000
fi
