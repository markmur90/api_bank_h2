#!/bin/bash

# Migraciones
python manage.py migrate

# Crear superusuario si no existe
echo "from django.contrib.auth import get_user_model; \
User = get_user_model(); \
User.objects.filter(username='markmur88').exists() or \
User.objects.create_superuser('markmur88', 'admin@example.com', 'Ptf8454Jd55')" \
| python manage.py shell

# Recolectar archivos estáticos
python manage.py collectstatic --noinput

# Iniciar el servidor
gunicorn bank_ghost.wsgi:application --bind 0.0.0.0:8000
