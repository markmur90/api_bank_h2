# File: heroku/api/gpt4/conexion/conexion_banco.py

from functools import lru_cache
from urllib.parse import urlparse
import json
import socket
import time
from typing import Any, Dict, Optional

import dns.resolver
import requests
from django.conf import settings
from api.configuraciones_api.helpers import get_conf
from api.gpt4.conexion.ssh_utils import ssh_request
from api.gpt4.models import Transfer
from api.gpt4.utils import generar_xml_pain001, registrar_log, default_request_headers
from django.core.exceptions import ObjectDoesNotExist
import os
import certifi
import hashlib

def get_settings() -> Dict[str, Any]:
    """Return all configuration values needed for the bank connection."""
    return {
        "BASE_URL":         get_conf("BASE_URL"),
        "TOKEN_PATH":       get_conf("TOKEN_PATH"),
        "AUTH_PATH":        get_conf("AUTH_PATH"),
        "SEND_PATH":        get_conf("SEND_PATH"),
        "STATUS_PATH":      get_conf("STATUS_PATH"),
        "TIMEOUT_REQUEST":  int(get_conf("TIMEOUT_REQUEST")),
        "DNS_BANCO":        get_conf("DNS_BANCO"),
        "DOMINIO_BANCO":    get_conf("DOMINIO_BANCO"),
        "RED_SEGURA_PREFIX": get_conf("RED_SEGURA_PREFIX"),
        "MOCK_PORT":        int(get_conf("MOCK_PORT")),
        "ALLOW_FAKE_BANK":  get_conf("ALLOW_FAKE_BANK") == "True",
        "BANK_USER":        get_conf("BANK_USER"),
        "BANK_PASS":        get_conf("BANK_PASS"),
        "login_url":        get_conf("SIMULADOR_LOGIN_URL"),
        "verify_url":       get_conf("SIMULADOR_VERIFY_URL"),
        "otp_url":          get_conf("OTP_URL"),
        "transfer_url":     get_conf("TRANSFER_URL"),
        "usuario":          get_conf("SIMULADOR_USERNAME"),
        "password":         get_conf("SIMULADOR_PASSWORD"),
        "token_endpoint":   get_conf("TOKEN_ENDPOINT"),
        "challenge_url":    get_conf("CHALLENGE_URL"),
        "status_url":       get_conf("STATUS_URL"),
        "verify_url_alt":   get_conf("VERIFY_URL"),        
        "verify_path":      get_conf("VERIFY_PATH"),
        "enable_cert_p":    get_conf("ENABLE_CERT_PINNING_FOR_BANK"),
        "pin_sha256":       get_conf("BANK_CERT_PIN_SHA256"),
        "base_dir":         get_conf("BASE_DIR"),
        "req_ca_bundle":    get_conf("REQUESTS_CA_BUNDLE"),
        "force_in_ssl":     get_conf("FORCE_INSECURE_SSL_FOR_BANK"),
    }

def _get_requests_verify() -> Any:
    """Devuelve el parámetro `verify` para requests según configuración.

    Prioriza un bundle CA personalizado definido en REQUESTS_CA_BUNDLE.
    Si FORCE_INSECURE_SSL_FOR_BANK=="1", desactiva la verificación (solo temporalmente).
    En caso contrario, usa la CA por defecto del sistema.
    """
    conf = get_settings()
    FORCE_INSECURE_SSL_FOR_BANK = conf["force_in_ssl"]
    REQUESTS_CA_BUNDLE = conf["req_ca_bundle"]
    # 1) Bypass temporal (mitigación controlada)
    if FORCE_INSECURE_SSL_FOR_BANK == "1":
        return False
    # 2) Bundle personalizado si existe
    bundle_path = REQUESTS_CA_BUNDLE
    if bundle_path and os.path.exists(bundle_path):
        return bundle_path
    # Usar CA del sistema (requests/certifi ya lo usan por defecto); devolvemos True explícitamente
    return True


def _read_expected_pin_sha256() -> Optional[str]:
    """
    Lee el pin SHA256 esperado desde env BANK_CERT_PIN_SHA256 o desde servers/ssl/pin.txt.
    Devuelve en formato con dos puntos en mayúsculas (ej: 'AA:BB:..').
    """
    conf = get_settings()
    pin_env = conf["pin_sha256"]
    base_dir_path = conf["base_dir"]
    if pin_env:
        return pin_env.strip()
    try:
        pin_path = os.path.join(base_dir_path, 'servers', 'ssl', 'pin.txt')
        if os.path.exists(pin_path):
            with open(pin_path, 'r', encoding='utf-8') as f:
                content = f.read().strip()
                # El archivo puede venir como 'sha256 Fingerprint=..'
                if 'Fingerprint=' in content:
                    return content.split('Fingerprint=')[-1].strip()
                return content
    except Exception:
        pass
    return None


def _format_sha256_colon(hex_bytes: bytes) -> str:
    hex_str = hex_bytes.hex().upper()
    return ':'.join(hex_str[i:i+2] for i in range(0, len(hex_str), 2))


def _request_with_optional_pinning(method: str, url: str, *, headers: Dict[str, str], json: Dict[str, Any], timeout: int) -> requests.Response:
    """
    Realiza la petición usando verify según _get_requests_verify().
    Si verify=False y ENABLE_CERT_PINNING_FOR_BANK=="1", hace pinning de certificado SHA256.
    """
    verify_value = _get_requests_verify()
    conf = get_settings()
    enable_cert = conf["enable_cert_p"]
    enable_pinning = enable_cert == "1"
    stream = verify_value is False and enable_pinning

    session = requests.Session()
    resp = session.request(
        method.upper(),
        url,
        json=json,
        headers=headers,
        timeout=timeout,
        verify=verify_value,
        stream=stream,
    )

    if stream:
        # Intentar obtener el certificado del peer y verificar pin
        try:
            conn = getattr(resp.raw, 'connection', None)
            sock = getattr(conn, 'sock', None)
            if sock is None and conn is not None:
                # urllib3 v2
                sock = getattr(conn, '_sock', None)
            if sock is not None and hasattr(sock, 'getpeercert'):
                der = sock.getpeercert(binary_form=True)
                digest = hashlib.sha256(der).digest()
                got = _format_sha256_colon(digest)
                expected = _read_expected_pin_sha256()
                if expected and got != expected:
                    resp.close()
                    raise requests.exceptions.SSLError(
                        f"Pinning SHA256 no coincide. Esperado {expected} != Obtenido {got}"
                    )
        finally:
            # Cerrar respuesta si estaba en stream
            resp.close()

    return resp


def esta_en_red_segura() -> bool:
    """Determina si estamos en la red segura del banco."""
    conf = get_settings()
    red_prefix = conf["RED_SEGURA_PREFIX"]
    try:
        ip_local = socket.gethostbyname(socket.gethostname())
        return ip_local.startswith(red_prefix)
    except Exception as e:
        registrar_log("conexion", f"❌ Error determinando red segura: {e}")
        return False


def resolver_ip_dominio(dominio: str) -> Optional[str]:
    """Resuelve el dominio bancario a su IP mediante DNS específico."""
    conf = get_settings()
    dns_banco = conf["DNS_BANCO"]
    resolver = dns.resolver.Resolver()
    if isinstance(dns_banco, str):
        dns_banco = [ip.strip() for ip in dns_banco.split(',') if ip.strip()]
    resolver.nameservers = dns_banco

    try:
        respuesta = resolver.resolve(dominio)
        for rdata in respuesta:
            ip = rdata.to_text()
            registrar_log("conexion", f"🔐 Resuelto {dominio} → {ip}")
            return ip
    except Exception as e:
        registrar_log("conexion", f"❌ Error DNS bancario: {e}")
    return None


def puerto_activo(host: str, puerto: int, timeout: int = 2) -> bool:
    """Verifica si el puerto está escuchando en el host dado."""
    try:
        with socket.create_connection((host, puerto), timeout=timeout):
            return True
    except Exception as e:
        registrar_log("conexion", f"❌ Puerto inaccesible {host}:{puerto} - {e}")
        return False


def make_request(
    method: str,
    path: str,
    token: Optional[str] = None,
    payload: Optional[Dict[str, Any]] = None,
    extra_headers: Optional[Dict[str, str]] = None
    ) -> requests.Response:
    """
    Ejecuta una petición al Simulador bancario.
    Si BASE_URL incluye puerto, hace request directo.
    Si no, usa túnel SSH o mock según esté_en_red_segura() y ALLOW_FAKE_BANK.
    """
    conf = get_settings()
    data = payload or {}
    headers: Dict[str, str] = {}

    # Incluir Authorization sólo si token no es None ni cadena vacía
    if token:
        # Si token es un dict (headers completos), extraer OTP y otros headers
        if isinstance(token, dict):
            headers.update(token)
            # Extraer el token real del header Authorization
            auth_header = token.get("Authorization", "")
            if auth_header.startswith("Bearer "):
                token = auth_header[7:]  # Remove "Bearer " prefix
        else:
            headers["Authorization"] = f"Bearer {token}"
    
    # Mezclar headers adicionales requeridos en la API
    if extra_headers:
        headers.update(extra_headers)

    # Normalizar path para que empiece con '/'
    if not path.startswith("/"):
        path = "/" + path

    base = conf["BASE_URL"].rstrip("/")
    parsed = urlparse(base)

    # Si BASE_URL trae puerto explícito → request directo
    if parsed.port:
        url = f"{base}{path}"
        registrar_log("conexion", f"➡️ {method} {url}")
        resp = _request_with_optional_pinning(
            method,
            url,
            headers=headers,
            json=data,
            timeout=conf["TIMEOUT_REQUEST"],
        )
    else:
        # Conexión vía SSH o mock
        host = parsed.hostname or conf["DOMINIO_BANCO"]
        port = parsed.port or 443

        if esta_en_red_segura():
            ip_destino = resolver_ip_dominio(host)
            if not ip_destino:
                raise RuntimeError(f"No se pudo resolver DNS de {host}")
            remote_host, remote_port = ip_destino, port
        else:
            if not conf["ALLOW_FAKE_BANK"]:
                raise RuntimeError("Red no segura y mock desactivado")
            remote_host, remote_port = host, conf["MOCK_PORT"]
            if not puerto_activo(remote_host, remote_port):
                raise RuntimeError(f"Mock no disponible en {remote_host}:{remote_port}")
            registrar_log("conexion", f"⚠️ Usando mock en {remote_host}:{remote_port}")

        # Para túnel SSH, indicamos el host original en el header Host
        headers["Host"] = host
        registrar_log("conexion", f"🔐 SSH tunnel -> {remote_host}:{remote_port}{path}")
        resp = ssh_request(
            method.upper(),
            remote_host,
            path,
            remote_port=remote_port,
            headers=headers,
            json=data,
            timeout=conf["TIMEOUT_REQUEST"],
        )

    try:
        resp.raise_for_status()
    except Exception as e:
        registrar_log("conexion", f"❌ Error {method} {path}: {e}")
        raise

    registrar_log("conexion", f"✅ {method} {path} → {resp.status_code}")
    return resp


def consultar_estado(token: str, payment_id: str) -> Dict[str, Any]:
    """Consulta el estado de una transferencia."""
    conf = get_settings()
    status_path = conf["STATUS_PATH"] or ""
    path = status_path.replace("{paymentId}", str(payment_id))
    if "{paymentId}" not in status_path:
        if not path.endswith(f"/{payment_id}"):
            sep = "" if path.endswith("/") else "/"
            path = f"{path}{sep}{payment_id}"
    if not path.startswith("/"):
        path = "/" + path
    resp = make_request("GET", path, token=token)
    return resp.json()


def login_simulador():
    token_path = get_conf("TOKEN_PATH")
    base_url = get_conf("BASE_URL")
    user = get_conf("BANK_USER")
    password = get_conf("BANK_PASS")
    url = f"{base_url}/{token_path}"
    response = _request_with_optional_pinning(
        'POST',
        url,
        headers={},
        json={"username": user, "password": password},
        timeout=10,
    )
    return response.json()["token"]


def obtener_transferencia(payment_id: str) -> str:
    """
    Obtiene el XML PAIN.001 de la transferencia desde el modelo y lo devuelve como cadena.
    """
    try:
        transfer = Transfer.objects.get(payment_id=payment_id)
    except Transfer.DoesNotExist:
        raise ValueError(f"Transferencia con payment_id '{payment_id}' no encontrada en la base de datos.")

    xml_content = generar_xml_pain001(transfer, payment_id)
    registrar_log(payment_id, tipo_log='XML', extra_info='XML PAIN.001 obtenido via modelo')
    return xml_content


def iniciar_transferencia(token, payload):
    conf = get_settings()
    base_path = conf["BASE_URL"]
    send_path = conf["SEND_PATH"]
    url = f"{base_path}{send_path}"
    response = _request_with_optional_pinning(
        'POST',
        url,
        headers={"Authorization": f"Bearer {token}"},
        json=payload,
        timeout=30,
    )
    return response.json()

def confirmar_transferencia(token, payment_id, otp):
    conf = get_settings()
    base_path = conf["BASE_URL"]
    verify_path = conf["verify_path"]
    url = f"{base_path}{verify_path}"
    response = _request_with_optional_pinning(
        'POST',
        url,
        headers={"Authorization": f"Bearer {token}"},
        json={"paymentId": payment_id, "otp": otp},
        timeout=30,
    )
    return response.json()


def ejecutar_flujo_completo():
    token = login_simulador()
    payload = {
        "paymentId": "206df230-f289-4d27-a2a5-27131ee68d72",
        "DbtrIBAN": "DE00500700100200044824",
        "CdtrIBAN": "DE00500700100200044874",
        "InstdAmt": 10.0,
        "Ccy": "EUR",
        "EndToEndId": "E2Ec1dce3c73ab85d47cf781caa4001a565",
        "InstrId": "ea376ca81f059ca30354a18022d37c13d12"
    }
    resp1 = iniciar_transferencia(token, payload)
    otp = resp1.get("otp")
    resp2 = confirmar_transferencia(token, payload["paymentId"], otp)
    return resp2



def obtener_token():
    conf = get_settings()
    base_url = conf["BASE_URL"]
    token_path = conf["TOKEN_PATH"]
    url = f"{base_url}{token_path}"
    response = _request_with_optional_pinning(
        'POST',
        url,
        headers={},
        json={"username": conf["usuario"], "password": conf["password"]},
        timeout=10,
    )
    response.raise_for_status()
    return response.json().get("token")

def solicitar_otp(token, payment_id):
    headers = {"Authorization": f"Bearer {token}"}
    conf = get_settings()
    base_url = conf["BASE_URL"]
    otp_path = conf["AUTH_PATH"]
    otp_url = f"{base_url}{otp_path}"
    response = _request_with_optional_pinning(
        'POST',
        otp_url,
        headers=headers,
        json={"payment_id": payment_id},
        timeout=10,
    )
    response.raise_for_status()
    return response.json()

def enviar_transferencia(token: str, payment_id: str, otp: str) -> dict:
    from api.gpt4.models import Transfer
    from api.gpt4.utils import registrar_log
    
    try:
        # 1. Obtener la transferencia de la base de datos
        transfer = Transfer.objects.get(payment_id=payment_id)
        
        # 2. Verificar si usar certificados SSL de Deutsche Bank
        from api.gpt4.services.transfer_services import verificar_certificados_disponibles, enviar_transferencia_con_certificados
        
        certificados_disponibles, _ = verificar_certificados_disponibles()
        
        if certificados_disponibles:
            # Usar certificados SSL de Deutsche Bank
            registrar_log(payment_id, tipo_log='TRANSFER', extra_info="Usando certificados SSL de Deutsche Bank")
            
            # Obtener credenciales del banco
            username = get_conf("BANK_USER")
            password = get_conf("BANK_PASS")
            
            if username and password:
                success, result = enviar_transferencia_con_certificados(payment_id, username, password)
                if success:
                    return result
                else:
                    registrar_log(payment_id, tipo_log='ERROR', error=result, extra_info="Fallback a método original")
            else:
                registrar_log(payment_id, tipo_log='WARNING', extra_info="Credenciales de banco no configuradas, usando método original")
        
        # 3. Método original (fallback) - USAR SCHEMA DEL MODELO
        transfer_data = transfer.to_schema_data()
        
        # Agregar campos adicionales que no están en el schema
        transfer_data.update({
            "payment_id": payment_id,
            "status": "PDNG"
        })
        
        # 4. Headers correctos con OTP en header
        base_headers = default_request_headers().copy()
        base_headers["Authorization"] = f"Bearer {token}"
        base_headers["otp"] = otp
        
        # 5. URL correcta del simulador usando get_conf()
        conf = get_settings()
        transfer_path = conf["SEND_PATH"]
        url_path = conf["BASE_URL"]
        url = f"{url_path}{transfer_path}"
        
        # 6. Registrar el intento de envío
        registrar_log(
            payment_id, 
            tipo_log='TRANSFER',
            headers_enviados=base_headers,
            request_body=transfer_data,
            extra_info="Enviando transferencia completa al simulador usando schema del modelo"
        )
        
        # 7. Enviar transferencia al simulador
        response = _request_with_optional_pinning(
            'POST',
            url,
            headers=base_headers,
            json=transfer_data,
            timeout=settings.TIMEOUT_REQUEST,
        )
        
        # 8. Registrar respuesta
        registrar_log(
            payment_id,
            tipo_log='TRANSFER',
            response_headers=dict(response.headers),
            response_text=response.text,
            extra_info="Respuesta recibida del simulador"
        )
        
        # 9. Manejar errores HTTP
        response.raise_for_status()
        
        # 10. Procesar respuesta
        data = response.json()
        
        # 11. Actualizar estado de la transferencia local
        if 'status' in data:
            transfer.status = data['status']
            transfer.save()
            
        # 12. Registrar éxito
        registrar_log(
            payment_id,
            tipo_log='TRANSFER',
            extra_info=f"Transferencia completada con estado: {data.get('status', 'UNKNOWN')}"
        )
        
        return data
        
    except Transfer.DoesNotExist:
        error_msg = f"Transferencia {payment_id} no encontrada en la base de datos local"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        raise Exception(error_msg)
        
    except requests.RequestException as e:
        error_msg = f"Error de conexión al simulador: {str(e)}"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        raise
        
    except Exception as e:
        error_msg = f"Error procesando transferencia: {str(e)}"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        raise Exception(error_msg)

