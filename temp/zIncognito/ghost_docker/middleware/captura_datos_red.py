import netifaces as ni
import os

INTERFAZ_RED = "wlan0"

def leer_dato_temporal(ruta):
    try:
        with open(ruta) as f:
            return f.read().strip()
    except FileNotFoundError:
        return "No disponible"

class IPMacMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        request.ip_anterior = leer_dato_temporal("tmp/ghostcache/ip_antes.txt")
        request.mac_anterior = leer_dato_temporal("tmp/ghostcache/mac_antes.txt")
        request.ip_actual = leer_dato_temporal("tmp/ghostcache/ip_actual.txt")
        request.mac_actual = leer_dato_temporal("tmp/ghostcache/mac_actual.txt")

        return self.get_response(request)

