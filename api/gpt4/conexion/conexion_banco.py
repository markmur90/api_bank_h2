"""Funciones de conexión con el banco remoto o su simulador local."""

import dns.resolver
import requests

from api.gpt4.conexion.conexion_ssh import ssh_request
import socket
import json

from functools import lru_cache

from api.gpt4.utils import (
    registrar_log,
    generar_xml_pain001,
    generar_archivo_aml,
    validar_xml_pain001,
    validar_aml_con_xsd,
)
from api.configuraciones_api.helpers import get_conf


@lru_cache
def get_settings():
    """Obtiene la configuración de conexión desde variables de entorno."""

    timeout = int(get_conf("TIMEOUT"))
    port = int(get_conf("MOCK_PORT"))
    allow_fake_bank = get_conf("ALLOW_FAKE_BANK").lower()
    return {
        "DNS_BANCO": get_conf("DNS_BANCO"),
        "DOMINIO_BANCO": get_conf("DOMINIO_BANCO"),
        "RED_SEGURA_PREFIX": get_conf("RED_SEGURA_PREFIX"),
        "ALLOW_FAKE_BANK": allow_fake_bank,
        "TIMEOUT": timeout,
        "MOCK_PORT": port,
    }


def esta_en_red_segura():
    conf = get_settings()
    red_prefix = conf["RED_SEGURA_PREFIX"]
    try:
        hostname = socket.gethostname()
        ip_local = socket.gethostbyname(hostname)
        return ip_local.startswith(red_prefix)
    except Exception:
        return False


def resolver_ip_dominio(dominio):
    conf = get_settings()
    dns_banco = conf["DNS_BANCO"]

    resolver = dns.resolver.Resolver()

    # Aseguramos que nameservers sea una lista de IPs
    if isinstance(dns_banco, str):
        dns_banco = [ip.strip() for ip in dns_banco.split(',') if ip.strip()]

    resolver.nameservers = dns_banco

    try:
        respuesta = resolver.resolve(dominio)
        for rdata in respuesta:
            ip = rdata.to_text()
            print(f"🔐 Resuelto {dominio} → {ip}")
            return ip
    except Exception as e:
        registrar_log("conexion", f"❌ Error DNS bancario: {e}")
        return None


def hacer_request_seguro(dominio, path="/api", metodo="GET", datos=None, headers=None):
    conf = get_settings()
    dominio_banco = conf["DOMINIO_BANCO"]
    dns_banco = conf["DNS_BANCO"]
    mock_port = conf["MOCK_PORT"]
    timeout = conf["TIMEOUT"]
    allow_fake_bank = conf["ALLOW_FAKE_BANK"]

    headers = headers or {}
    
    if esta_en_red_segura():
        ip_destino = resolver_ip_dominio(dominio_banco)
        if not ip_destino:
            registrar_log("conexion", f"❌ No se pudo resolver {dominio_banco} vía DNS bancario.")
            return None
    else:
        if allow_fake_bank:
            ip_destino = dns_banco
            dominio = dominio_banco
            puerto = mock_port

            if not puerto_activo(ip_destino, puerto):
                registrar_log("conexion", f"❌ Mock local en {ip_destino}:{puerto} no está activo. Cancelando.")
                return None

            registrar_log("conexion", f"⚠️ Red no segura. Usando servidor local mock en {ip_destino}:{puerto}.")
        else:
            registrar_log("conexion", "🚫 Red no segura y ALLOW_FAKE_BANK desactivado. Cancelando.")
            return None

    headers["Host"] = dominio

    try:
        r = ssh_request(
            metodo.upper(),
            dominio,
            path,
            headers=headers,
            json=datos,
            timeout=timeout,
        )
        registrar_log("conexion", f"✅ Petición a {dominio}{path} → {r.status_code}")
        return r
    except Exception as e:
        registrar_log("conexion", f"❌ Error en petición HTTPS a {dominio}: {str(e)}")
        return None


def puerto_activo(host, puerto, timeout=2):
    try:
        with socket.create_connection((host, puerto), timeout=timeout):
            return True
    except Exception:
        return False


# Funciones auxiliares para peticiones autenticadas

def obtener_token_desde_simulador(username, password):
    """Solicita un token al simulador bancario usando la URL definida en las
    variables de entorno."""
    conf = get_settings()
    dns_banco = conf["DNS_BANCO"]
    mock_port = conf["MOCK_PORT"]
    try:
        r = ssh_request(
            "POST",
            dns_banco,
            "/api/token/",
            remote_port=mock_port,
            json={"username": username, "password": password},
            timeout=conf["TIMEOUT"],
        )
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
    conf = get_settings()
    dominio_banco = conf["DOMINIO_BANCO"]
    dns_banco = conf["DNS_BANCO"]
    mock_port = conf["MOCK_PORT"]
    timeout = conf["TIMEOUT"]

    usar_conexion = request.session.get("usar_conexion_banco", False)

    headers = headers or {}

    if usar_conexion == "oficial":
        token = obtener_token_desde_simulador("493069k1", "bar1588623")
        if token:
            headers["Authorization"] = f"Bearer {token}"
        else:
            registrar_log("conexion", "❌ No se pudo obtener token del simulador para oficial.")
            return {"error": "Fallo autenticación oficial"}

    if usar_conexion and usar_conexion == "oficial":
        return hacer_request_seguro(dominio_banco, path, metodo, datos, headers)

    return hacer_request_seguro(dominio_banco, path, metodo, datos, headers)


def enviar_transferencia_conexion(request, transfer, token: str, otp: str):
    """Envía una transferencia usando :func:`hacer_request_banco`."""
    body = transfer.to_schema_data()
    pid = transfer.payment_id
    headers = {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": f"Bearer {token}",
        "Idempotency-Id": pid,
        "Correlation-Id": pid,
        "Otp": otp,
    }

    registrar_log(pid, headers_enviados=headers, request_body=body,
                 tipo_log="TRANSFER", extra_info="Enviando transferencia vía conexion_banco")

    resp = hacer_request_banco(
        request, path="/api/transferencia", metodo="POST", datos=body, headers=headers
    )

    if resp is None:
        registrar_log(pid, tipo_log="ERROR", error="Sin respuesta de conexion_banco")
        raise Exception("Sin respuesta de la conexión bancaria")

    if isinstance(resp, requests.Response):
        response_headers = dict(resp.headers)
        text = resp.text
        try:
            resp.raise_for_status()
        except requests.RequestException as e:
            registrar_log(pid, error=str(e), tipo_log="ERROR",
                         extra_info="Error HTTP conexión bancaria")
            raise
        data = resp.json()
    else:
        response_headers = {}
        text = json.dumps(resp)
        data = resp

    registrar_log(pid, tipo_log="TRANSFER", response_text=text,
                 headers_enviados=response_headers,
                 extra_info="Respuesta del API SEPA (conexion)")

    transfer.auth_id = data.get("authId")
    transfer.status = data.get("transactionStatus", transfer.status)
    transfer.save()

    registrar_log(pid, tipo_log="TRANSFER", extra_info="Transferencia enviada con éxito via conexion_banco")

    try:
        xml_path = generar_xml_pain001(transfer, pid)
        aml_path = generar_archivo_aml(transfer, pid)
        validar_xml_pain001(xml_path)
        validar_aml_con_xsd(aml_path)
        registrar_log(pid, tipo_log="TRANSFER", extra_info="Validación XML/AML completada")
    except Exception as e:
        registrar_log(pid, error=str(e), tipo_log="ERROR", extra_info="Error generando XML/AML posterior")

    return resp
