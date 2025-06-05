# reconocimiento/middleware/captura_datos_red.py

from django.conf import settings
from django.utils.deprecation import MiddlewareMixin
import os
import netifaces as ni

CACHE_DIR = os.path.join(settings.BASE_DIR, "tmp", "ghostcache")

def leer_dato_temporal(nombre):
    ruta = os.path.join(CACHE_DIR, nombre)
    try:
        with open(ruta) as f:
            return f.read().strip()
    except FileNotFoundError:
        return "No disponible"

class IPMacMiddleware(MiddlewareMixin):
    def __call__(self, request):
        request.ip_anterior  = leer_dato_temporal("ip_antes.txt")
        request.mac_anterior = leer_dato_temporal("mac_antes.txt")
        request.ip_actual    = leer_dato_temporal("ip_actual.txt")
        request.mac_actual   = leer_dato_temporal("mac_actual.txt")
        return super().__call__(request)

class TemaMiddleware(MiddlewareMixin):
    def __call__(self, request):
        if request.user.is_authenticated:
            request.tema_usuario         = getattr(request.user.perfilusuario, "tema", "oscuro")
            request.modo_verificacion_tor = getattr(request.user, "verificacion_tor", "backend")
        else:
            request.tema_usuario = "oscuro"
        return super().__call__(request)
