# simulador_banco/api_login.py
import json
from django.contrib.auth import authenticate
from django.http import JsonResponse
import jwt
import datetime
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt

def emitir_jwt_simulador(user):
    payload = {
        "username": user.username,
        "iat": datetime.datetime.utcnow(),
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }
    return jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')

@csrf_exempt
def login_api_simulador(request):
    if request.method != "POST":
        return JsonResponse({"error": "Sólo POST"}, status=405)

    data = json.loads(request.body.decode("utf-8"))
    username = data.get("username")
    password = data.get("password")

    user = authenticate(username=username, password=password)
    if user:
        token = emitir_jwt_simulador(user)
        return JsonResponse({"token": token})
    else:
        return JsonResponse({"error": "Credenciales inválidas"}, status=401)
