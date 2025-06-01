import dns.resolver
import requests
import socket
import os

from api.gpt4.utils import registrar_log

DNS_BANCO = "160.83.58.33"
DOMINIO_BANCO = "internet.dbbank-de"
RED_SEGURA_PREFIX = "193.150.166."
TIMEOUT = 10

def esta_en_red_segura():
    try:
        hostname = socket.gethostname()
        ip_local = socket.gethostbyname(hostname)
        return ip_local.startswith(RED_SEGURA_PREFIX)
    except Exception:
        return False

def resolver_ip_dominio(dominio):
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
    headers = headers or {}

    if esta_en_red_segura():
        ip_destino = resolver_ip_dominio(dominio)
        if not ip_destino:
            registrar_log("conexion", f"❌ No se pudo resolver {dominio} vía DNS bancario.")
            return None
    else:
        if os.getenv("ALLOW_FAKE_BANK", "false").lower() == "true":
            ip_destino = "127.0.0.1"
            dominio = "mock.bank.test"
            puerto = 443

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

def puerto_activo(host, puerto, timeout=2):
    try:
        with socket.create_connection((host, puerto), timeout=timeout):
            return True
    except Exception:
        return False


# ============================
# Wrapper inteligente por sesión
# ============================
from django.conf import settings

def hacer_request_banco(request, path="/api", metodo="GET", datos=None, headers=None):
    usar_conexion = request.session.get("usar_conexion_banco", False)
    if usar_conexion:
        return hacer_request_seguro(DOMINIO_BANCO, path, metodo, datos, headers)
    # Modo normal/local
    registrar_log("conexion", "🔁 Usando modo local de conexión bancaria")
    url = f"https://80.78.30.242:9000{path}"
    try:
        respuesta = requests.request(metodo, url, json=datos, headers=headers, timeout=TIMEOUT)
        return respuesta.json()
    except Exception as e:
        registrar_log("conexion", f"❌ Error al conectar al VPS mock: {e}")
        return None
