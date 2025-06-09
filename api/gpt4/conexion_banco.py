import dns.resolver
import requests
import socket
import os
from django.conf import settings

from api.gpt4.utils import registrar_log, get_conf
from functools import lru_cache
from api.configuraciones_api.helpers import get_conf

@lru_cache
def get_settings():
    timeout = int(600)
    port = int(get_conf("MOCK_PORT"))
    return {
        "DNS_BANCO":            get_conf("DNS_BANCO"),
        "DOMINIO_BANCO":        get_conf("DOMINIO_BANCO"),
        "RED_SEGURA_PREFIX":    get_conf("RED_SEGURA_PREFIX"),
        "TIMEOUT":              timeout,
        "MOCK_PORT":            port,
    }

def esta_en_red_segura():
    settings = get_settings()
    RED_SEGURA_PREFIX = settings["RED_SEGURA_PREFIX"]
    try:
        hostname = socket.gethostname()
        ip_local = socket.gethostbyname(hostname)
        return ip_local.startswith(RED_SEGURA_PREFIX)
    except Exception:
        return False

def resolver_ip_dominio(dominio):
    settings = get_settings()
    DNS_BANCO = settings["DNS_BANCO"]
    
    resolver = dns.resolver.Resolver()
    resolver.nameservers = [DNS_BANCO]
    try:
        respuesta = resolver.resolve(dominio)
        ip = respuesta[0].to_text()
        print(f"🔐 Resuelto {dominio} → {ip}")
        return ip
    except Exception as e:
        registrar_log("conexion", f"❌ Error DNS bancario: {e}")
        return None

def hacer_request_seguro(dominio, path="/api", metodo="GET", datos=None, headers=None):
    settings = get_settings()
    DOMINIO_BANCO = settings["DOMINIO_BANCO"]
    MOCK_PORT = settings["MOCK_PORT"]
    TIMEOUT = settings["TIMEOUT"]
    
    headers = headers or {}
    
    if esta_en_red_segura():
        ip_destino = resolver_ip_dominio(dominio)
        if not ip_destino:
            registrar_log("conexion", f"❌ No se pudo resolver {dominio} vía DNS bancario.")
            return None
    else:
        if os.getenv("ALLOW_FAKE_BANK", "false").lower() == "true":
            ip_destino = "127.0.0.1"
            dominio = DOMINIO_BANCO
            puerto = MOCK_PORT

            if not puerto_activo(ip_destino, puerto):
                registrar_log("conexion", f"❌ Mock local en {ip_destino}:{puerto} no está activo. Cancelando.")
                return None

            registrar_log("conexion", f"⚠️ Red no segura. Usando servidor local mock en {ip_destino}:{puerto}.")
        else:
            registrar_log("conexion", "🚫 Red no segura y ALLOW_FAKE_BANK desactivado. Cancelando.")
            return None

    url = f"https://{ip_destino}{path}"
    headers["Host"] = dominio

    try:
        if metodo.upper() == "GET":
            r = requests.get(url, headers=headers, timeout=TIMEOUT, verify=False)
        else:
            r = requests.post(url, headers=headers, json=datos, timeout=TIMEOUT, verify=False)
        registrar_log("conexion", f"✅ Petición a {dominio}{path} → {r.status_code}")
        return r
    except requests.RequestException as e:
        registrar_log("conexion", f"❌ Error en petición HTTPS a {dominio}: {str(e)}")
        return None

def puerto_activo(host, puerto, timeout=int(2)):
    try:
        with socket.create_connection((host, puerto), timeout=timeout):
            return True
    except Exception:
        return False

def hacer_request_banco_O(request, path="/api", metodo="GET", datos=None, headers=None):
    settings = get_settings()
    DOMINIO_BANCO = settings["DOMINIO_BANCO"]
    DNS_BANCO = settings["DNS_BANCO"]
    MOCK_PORT = settings["MOCK_PORT"]
    TIMEOUT = settings["TIMEOUT"]

    usar_conexion = request.session.get("usar_conexion_banco", False)
    if usar_conexion:
        return hacer_request_seguro(DOMINIO_BANCO, path, metodo, datos, headers)

    registrar_log("conexion", "🔁 Usando modo local de conexión bancaria")
    url = f"https://{DNS_BANCO}:{MOCK_PORT}{path}"
    try:
        respuesta = requests.request(metodo, url, json=datos, headers=headers, timeout=TIMEOUT)
        return respuesta.json()
    except Exception as e:
        registrar_log("conexion", f"❌ Error al conectar al VPS mock: {e}")
        return None


# api/gpt4/conexion_banco.py (al final del archivo)
# Requiere: tener 'requests' importado + `get_settings()` ya disponible
from api.gpt4.utils import registrar_log
import requests

def obtener_token_desde_simulador(username, password):
    settings_data = get_settings()
    dominio = settings_data["DOMINIO_BANCO"]
    url = f"https://{dominio}/api/login/"
    try:
        r = requests.post(url, json={"username": username, "password": password}, verify=False)
        if r.status_code == 200:
            return r.json().get("token")
        registrar_log("conexion", f"Login fallido: {r.text}")
    except Exception as e:
        registrar_log("conexion", f"❌ Error al obtener token del simulador: {e}")
    return None

def hacer_request_banco_autenticado(request, path="/api", metodo="GET", datos=None, username="493069k1", password="bar1588623"):
    token = obtener_token_desde_simulador(username, password)
    if not token:
        return {"error": "No se pudo obtener token del simulador"}
    
    # Si ya hay headers, los respeta y solo añade el JWT
    headers = {"Authorization": f"Bearer {token}"}
    return hacer_request_banco(request, path=path, metodo=metodo, datos=datos, headers=headers)



def hacer_request_banco(request, path="/api", metodo="GET", datos=None, headers=None):
    settings = get_settings()
    DOMINIO_BANCO = settings["DOMINIO_BANCO"]
    DNS_BANCO = settings["DNS_BANCO"]
    MOCK_PORT = settings["MOCK_PORT"]
    TIMEOUT = settings["TIMEOUT"]

    usar_conexion = request.session.get("usar_conexion_banco", False)

    headers = headers or {}

    if usar_conexion == "oficial":
        token = obtener_token_desde_simulador("493069k1", "bar1588623")
        if token:
            headers["Authorization"] = f"Bearer {token}"
        else:
            registrar_log("conexion", "❌ No se pudo obtener token del simulador para oficial.")
            return {"error": "Fallo autenticación oficial"}

    if usar_conexion:
        return hacer_request_seguro(DOMINIO_BANCO, path, metodo, datos, headers)

    registrar_log("conexion", "🔁 Usando modo local de conexión bancaria")
    url = f"https://{DNS_BANCO}:{MOCK_PORT}{path}"
    try:
        respuesta = requests.request(metodo, url, json=datos, headers=headers, timeout=TIMEOUT)
        return respuesta.json()
    except Exception as e:
        registrar_log("conexion", f"❌ Error al conectar al VPS mock: {e}")
        return None
