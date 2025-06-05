#!/bin/bash

# Ruta donde desplegamos
APP_DIR="/opt/simulador_banco"
PORT=9180

echo "📦 Instalando entorno para simulador bancario en $APP_DIR"

# Crear entorno
sudo mkdir -p $APP_DIR
cd $APP_DIR
python3 -m venv venv
source venv/bin/activate

# Crear carpeta de logs si no existe
LOG_DIR="$APP_DIR/logs"
mkdir -p "$LOG_DIR"
chmod 755 "$LOG_DIR"

# Instalar Django y Gunicorn
pip install --upgrade pip
pip install django gunicorn

# Crear proyecto Django
django-admin startproject simulador_banco .
mkdir banco
touch banco/__init__.py

# Crear archivos de app banco
cat > banco/views.py <<EOF
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json

@csrf_exempt
def recibir_transferencia(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            required_fields = ["paymentIdentification", "debtor", "creditor", "instructedAmount"]
            if not all(field in data for field in required_fields):
                return JsonResponse({"estado": "RJCT", "mensaje": "Campos faltantes"}, status=400)
            return JsonResponse({"estado": "ACSC", "mensaje": "Transferencia aceptada"}, status=200)
        except Exception as e:
            return JsonResponse({"estado": "ERRO", "mensaje": str(e)}, status=500)
    return JsonResponse({"mensaje": "Solo POST permitido"}, status=405)
EOF

cat > banco/urls.py <<EOF
from django.urls import path
from .views import recibir_transferencia

urlpatterns = [
    path("recibir/", recibir_transferencia, name="recibir_transferencia"),
]
EOF

# Agregar urls a simulador_banco
sed -i "/from django.urls import path/a\\from django.urls import include" simulador_banco/urls.py
sed -i "/urlpatterns = \[/a\\    path('api/gpt4/', include('banco.urls'))," simulador_banco/urls.py

# Modificar settings.py
sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ['*']/" simulador_banco/settings.py

# Migraciones básicas
python manage.py migrate

# Lanzar con gunicorn
echo "🚀 Lanzando servidor en puerto $PORT"
gunicorn simulador_banco.wsgi:application --bind 0.0.0.0:$PORT --daemon

echo "✅ Simulador bancario activo en http://$(curl -s ifconfig.me):$PORT/api/gpt4/recibir/"
