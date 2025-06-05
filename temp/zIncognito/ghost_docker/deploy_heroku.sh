#!/bin/bash

APP_NAME="ghtapp"
DJANGO_SECRET_KEY="_ctm45af%%v+l4o9vh(qc)bonxlmcddkrr5pi8ocb=9t20=l&x"
EMAIL_SUPERUSER="markmur88@proton.me"
USERNAME_SUPERUSER="markmur88"
PASSWORD_SUPERUSER="Ptf8454Jd55"

echo "🚀 Iniciando despliegue en Heroku..."

# Login
heroku whoami &>/dev/null || heroku login

# Crear app si no existe
if ! heroku apps:info -a $APP_NAME &>/dev/null; then
    echo "📦 Creando app Heroku: $APP_NAME"
    heroku create $APP_NAME
fi

# Crear base de datos
heroku addons:create heroku-postgresql:hobby-dev -a $APP_NAME

# Establecer variables de entorno
heroku config:set \
    DJANGO_SECRET_KEY="$DJANGO_SECRET_KEY" \
    DJANGO_SETTINGS_MODULE=bank_ghost.settings \
    ALLOWED_HOSTS=$APP_NAME.herokuapp.com \
    --app $APP_NAME

# Asegurarse de tener archivos necesarios
echo "🧾 Verificando Procfile y runtime.txt..."
echo "web: gunicorn bank_ghost.wsgi --log-file -" > Procfile
echo "python-3.11.9" > runtime.txt

# Subir código
git add . && git commit -m "🚀 Deploy to Heroku" || echo "📁 Nada que commitear"
git push https://git.heroku.com/$APP_NAME.git main

# Migraciones
echo "⚙️ Aplicando migraciones..."
heroku run python manage.py migrate --app $APP_NAME

# Crear superusuario automáticamente
echo "👤 Creando superusuario si no existe..."
heroku run python manage.py shell --app $APP_NAME <<EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='$USERNAME_SUPERUSER').exists():
    User.objects.create_superuser('$USERNAME_SUPERUSER', '$EMAIL_SUPERUSER', '$PASSWORD_SUPERUSER')
EOF

echo "✅ Despliegue completo: https://$APP_NAME.herokuapp.com/"
