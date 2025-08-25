# api/gpt4/services/transfer_services.py

from sshtunnel import SSHTunnelForwarder
import requests
import time
import logging
import ssl
import socket
from requests.adapters import HTTPAdapter
from urllib3.util.ssl_ import create_urllib3_context
from api.configuraciones_api.helpers import get_conf
from django.conf import settings
import os
import uuid
from datetime import datetime
from typing import Optional
from urllib.parse import urlparse
import ipaddress

# Importar recursos existentes
from api.gpt4.conexion.conexion_banco import make_request, get_settings as banco_settings
from api.gpt4.utils import registrar_log, generar_xml_pain001, generar_archivo_aml, default_request_headers
from api.gpt4.models import Transfer

logger = logging.getLogger(__name__)

class DeutscheBankSSLAdapter(HTTPAdapter):
    """
    Adaptador personalizado para requests que usa certificados SSL
    para conectarse al servidor Deutsche Bank.
    """
    def __init__(self, cert_path, key_path, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.cert_path = cert_path
        self.key_path = key_path
    
    def init_poolmanager(self, *args, **kwargs):
        context = create_urllib3_context()
        context.load_cert_chain(self.cert_path, self.key_path)
        
        # Deshabilitar verificación SSL para evitar errores de CA
        context.verify_mode = ssl.CERT_NONE
        context.check_hostname = False
            
        kwargs['ssl_context'] = context
        return super().init_poolmanager(*args, **kwargs)        

    def proxy_manager_for(self, *args, **kwargs):
        context = create_urllib3_context()
        context.load_cert_chain(self.cert_path, self.key_path)
        
        # Deshabilitar verificación SSL para evitar errores de CA
        context.verify_mode = ssl.CERT_NONE
        context.check_hostname = False
        
        kwargs['ssl_context'] = context
        return super().proxy_manager_for(*args, **kwargs)

class DeutscheBankClient:
    """
    Cliente para Deutsche Bank usando certificados SSL personalizados.
    Se conecta directamente a https://193.150.166.1:443
    """
    def __init__(self):
        # Rutas de los certificados
        ruta = get_conf("BASE_DIR")
        base_path = os.path.join(ruta, 'deutsche_bank_certs')
        self.cert_path = os.path.join(base_path, 'deutsche_bank_certificate.pem')
        self.key_path = os.path.join(base_path, 'deutsche_bank_private_key.pem')
        self.ca_cert = os.path.join(base_path, 'ca-bundle-custom.pem')
        # Base URL configurable
        try:
            configured_base = get_conf("BASE_URL")
        except Exception:
            configured_base = os.environ.get("BASE_URL", "https://193.150.166.1:443")
        self.base_url = configured_base or "https://193.150.166.1:443"

        # Alternativa por dominio para forzar SNI correcto cuando la base es IP
        try:
            dominio_banco = get_conf("DOMINIO_BANCO")
        except Exception:
            dominio_banco = os.environ.get("DOMINIO_BANCO")
        self.alt_base_url = f"https://{dominio_banco}:443" if dominio_banco else None
        
        # Verificar que los certificados existan
        if not os.path.exists(self.cert_path):
            raise FileNotFoundError(f"Certificado no encontrado: {self.cert_path}")
        if not os.path.exists(self.key_path):
            raise FileNotFoundError(f"Clave privada no encontrada: {self.key_path}")
        
        # Si no existe el CA bundle, usar False para deshabilitar verificación
        if not os.path.exists(self.ca_cert):
            logger.warning(f"CA bundle no encontrado: {self.ca_cert}. Deshabilitando verificación SSL.")
            self.ca_cert = False

    
    def _create_session(self):
        """
        Crea una nueva sesión de requests con certificados SSL.
        - Respeta flags del entorno: FORCE_INSECURE_SSL_FOR_BANK y REQUESTS_CA_BUNDLE.
        - Evita hostname mismatch cuando base_url es una IP.
        """
        session = requests.Session()
        session.cert = (self.cert_path, self.key_path)

        session.headers.update({
            'User-Agent': 'DeutscheBank-Client/1.0',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })

        # Detectar si el host del base_url es IP para manejar hostname
        try:
            host = urlparse(self.base_url).hostname or ""
            ipaddress.ip_address(host)
            host_is_ip = True
        except ValueError:
            host_is_ip = False

        # Leer flags desde configuración central (BD/env) usando banco_settings()
        conf = banco_settings()
        force_insecure = conf.get("force_in_ssl", "0")
        requests_ca_bundle = conf.get("req_ca_bundle")

        # Determinar parámetro verify para requests
        if str(force_insecure) == "1":
            verify_value = False
        elif requests_ca_bundle and os.path.exists(str(requests_ca_bundle)):
            verify_value = str(requests_ca_bundle)
        elif self.ca_cert and isinstance(self.ca_cert, str) and os.path.exists(self.ca_cert):
            verify_value = self.ca_cert
        else:
            verify_value = True  # CA del sistema

        session.verify = verify_value

        # Configurar SSLContext cuando verificamos
        if verify_value is not False:
            ssl_context = create_urllib3_context()
            ssl_context.load_cert_chain(self.cert_path, self.key_path)

            if isinstance(verify_value, str):
                ssl_context.load_verify_locations(cafile=verify_value)
                ssl_context.verify_mode = ssl.CERT_REQUIRED
            else:
                ssl_context.load_default_certs()
                ssl_context.verify_mode = ssl.CERT_REQUIRED

            # Evitar hostname mismatch cuando usamos IP
            ssl_context.check_hostname = not host_is_ip

            class CustomHTTPAdapter(HTTPAdapter):
                def init_poolmanager(self, *args, **kwargs):
                    kwargs['ssl_context'] = ssl_context
                    return super().init_poolmanager(*args, **kwargs)

            session.mount('https://', CustomHTTPAdapter())

        return session
    
    def test_connection(self):
        """
        Prueba la conectividad SSL con el servidor del banco.
        """
        try:
            # Crear conexión directa por socket
            sock = socket.create_connection(('193.150.166.1', 443), timeout=10)
            
            # Configurar contexto SSL con certificados
            context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
            context.load_cert_chain(certfile=self.cert_path, keyfile=self.key_path)
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            # Envolver el socket SIN server_hostname cuando check_hostname=False
            ssl_sock = context.wrap_socket(sock)
            
            # Realizar handshake explícito
            ssl_sock.do_handshake()
            
            # Verificar conexión
            logger.info(f"Conexión SSL exitosa: {ssl_sock.version()}")
            ssl_sock.close()
            return True
        except ssl.SSLError as e:
            logger.error(f"Error SSL: {e}")
            return False
        except socket.error as e:
            logger.error(f"Error de socket: {e}")
            return False
        except Exception as e:
            logger.error(f"Error inesperado: {e}")
            return False
    
    def obtener_token(self, username: str, password: str):
        """
        Obtiene token usando credenciales oficiales del banco.
        No usa CLIENT_ID ni CLIENT_SECRET.
        """
        try:
            # Crear nueva sesión para la petición
            session = self._create_session()
            
            login_path = get_conf("TOKEN_PATH")
            url = f"{self.base_url}{login_path}"
            
            payload = {
                "username": username,
                "password": password,
                "grant_type": "password"
            }
            
            response = session.post(url, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            token = data["access_token"]
            expires = time.time() + data.get("expires_in", 300)
            
            logger.info("Token obtenido de Deutsche Bank")
            return token, expires
            
        except Exception as e:
            logger.error(f"Error obteniendo token: {e}")
            raise
    
    def generar_challenge_otp(self, payment_id: str, token: str, method: str = "PUSHTAN"):
        """
        Genera challenge OTP automático usando PUSHTAN.
        """
        try:
            # Crear nueva sesión para la petición
            session = self._create_session()
            
            challenge_path = get_conf("AUTH_PATH")
            url = f"{self.base_url}{challenge_path}"
            
            headers = {"Authorization": f"Bearer {token}"}
            payload = {
                "payment_id": payment_id,
                "method": method,
                "auto_generate": True  # Para OTP automático
            }
            
            response = session.post(url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            challenge_id = data["challenge_id"]
            otp_code = data.get("otp_code")  # OTP automático
            
            logger.info(f"Challenge {method} generado automáticamente: {challenge_id}")
            return challenge_id, otp_code
            
        except Exception as e:
            logger.error(f"Error generando challenge OTP: {e}")
            raise
    
    def enviar_transferencia(self, payment_id: str, token: str, otp_code: str = None):
        """
        Envía transferencia usando certificados SSL.
        Si no se proporciona OTP, se genera automáticamente.
        """
        try:
            # Si no hay OTP, generarlo automáticamente
            if not otp_code:
                challenge_id, otp_code = self.generar_challenge_otp(payment_id, token)
            
            # Crear nueva sesión para la petición
            session = self._create_session()
            
            transfer_path = get_conf("SEND_PATH")
            url = f"{self.base_url}{transfer_path}"
            
            headers = default_request_headers().copy()
            headers.update({"Authorization": f"Bearer {token}"})
            payload = {
                "payment_id": payment_id,
                "otp": otp_code,
            }
            
            response = session.post(url, json=payload, headers=headers, timeout=30)
            if response.status_code == 404 and self.alt_base_url:
                # Reintentar con dominio (SNI correcto) si el host por IP no encuentra el path
                alt_url = f"{self.alt_base_url}{transfer_path}"
                logger.warning(f"404 en {url}. Reintentando con {alt_url}")
                response = session.post(alt_url, json=payload, headers=headers, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            logger.info("Transferencia procesada por Deutsche Bank")
            return True, data
            
        except requests.HTTPError as e:
            logger.error(f"Error en transferencia: {e} – {e.response.text}")
            return False, e.response.text
        except Exception as e:
            logger.error(f"Error inesperado en transferencia: {e}")
            return False, str(e)

class SSHSimulatorTunnel:
    """
    Context manager para abrir y cerrar un túnel SSH
    hacia el Simulador bancario.
    """
    def __enter__(self):
        # Mover get_conf() dentro de la función
        ssh_host = get_conf("SSH_HOST")
        ssh_port = int(get_conf("SSH_PORT"))
        ssh_user = get_conf("SSH_USER")
        ssh_pass = get_conf("SSH_PASSWORD")
        remote_sim_host = "127.0.0.1"
        remote_sim_port = int(get_conf("MOCK_PORT", "9181"))
        
        self.tunnel = SSHTunnelForwarder(
            (ssh_host, ssh_port),
            ssh_username=ssh_user,
            ssh_password=ssh_pass,
            remote_bind_address=(remote_sim_host, remote_sim_port),
            # local_bind_address puede omitirse para puerto dinámico
        )
        self.tunnel.start()
        # Base URL apuntando al túnel local
        self.base_url = f"http://127.0.0.1:{self.tunnel.local_bind_port}"
        logger.debug(f"SSH Tunnel iniciado en {self.base_url}")
        return self.base_url

    def __exit__(self, exc_type, exc, tb):
        self.tunnel.stop()
        logger.debug("SSH Tunnel cerrado")


def obtener_token_simulador(username: str, password: str):
    """
    Llama a POST /api/generar_token pasando credenciales oficiales.
    Devuelve (token, expires_at_unix).
    """
    with SSHSimulatorTunnel() as base:
        # Usar get_conf() para la URL de login
        login_path = get_conf("TOKEN_PATH")
        url = f"{base}{login_path}"
        resp = requests.post(url, json={"username": username, "password": password})
        resp.raise_for_status()
        data = resp.json()
        token = data["access_token"]
        expires = time.time() + data.get("expires_in", 300)
        logger.info("Token obtenido del Simulador")
        return token, expires


def generar_challenge_simulador(payment_id: str, token: str, method: str):
    """
    Llama a POST /api/challenge para generar OTP.
    `method` puede ser 'MTAN' o 'PHOTOTAN'.
    Retorna challenge_id (y opcional imagen en base64 si PhotoTAN).
    """
    with SSHSimulatorTunnel() as base:
        # Usar get_conf() para la URL de challenge
        challenge_path = get_conf("AUTH_PATH")
        url = f"{base}{challenge_path}"
        headers = {"Authorization": f"Bearer {token}"}
        resp = requests.post(url, json={"payment_id": payment_id, "method": method}, headers=headers)
        resp.raise_for_status()
        data = resp.json()
        cid = data["challenge_id"]
        img64 = data.get("image_base64")
        logger.info(f"Challenge {method} generado: {cid}")
        return cid, img64


def enviar_transferencia_simulador(payment_id: str, token: str, otp_code: str):
    """
    Llama a POST /api/transferencia con payment_id, OTP y token.
    Devuelve (True, respuesta_json) o (False, mensaje_error).
    """
    with SSHSimulatorTunnel() as base:
        # Usar get_conf() para la URL de transferencia
        transfer_path = get_conf("SEND_PATH")
        url = f"{base}{transfer_path}"
        headers = {"Authorization": f"Bearer {token}"}
        payload = {
            "payment_id": payment_id,
            "otp": otp_code,
        }
        resp = requests.post(url, json=payload, headers=headers)
        try:
            resp.raise_for_status()
        except requests.HTTPError as e:
            logger.error(f"Error en transferencia: {e} – {resp.text}")
            return False, resp.text
        data = resp.json()
        logger.info("Transferencia procesada por el Simulador")
        return True, data

# ============================================================================
# FUNCIONES INTEGRADAS CON RECURSOS EXISTENTES
# ============================================================================

def enviar_transferencia_con_certificados(payment_id: str, username: str, password: str):
    """
    Función principal que integra certificados SSL con recursos existentes.
    Usa el cliente Deutsche Bank con certificados y OTP automático PUSHTAN.
    """
    try:
        # 1. Obtener la transferencia de la base de datos
        transfer = Transfer.objects.get(payment_id=payment_id)
        
        # 2. Crear cliente Deutsche Bank con certificados SSL
        client = DeutscheBankClient()
        
        # 2.1. Probar conexión SSL antes de continuar
        registrar_log(payment_id, tipo_log='CONNECTION', extra_info="Probando conexión SSL con Deutsche Bank")
        if not client.test_connection():
            error_msg = "No se pudo establecer conexión SSL con el servidor del banco"
            registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
            return False, error_msg
        
        # 3. Obtener token usando credenciales oficiales
        registrar_log(payment_id, tipo_log='AUTH', extra_info="Obteniendo token de Deutsche Bank con certificados SSL")
        token, expires = client.obtener_token(username, password)
        
        # 4. Generar OTP automático con PUSHTAN
        registrar_log(payment_id, tipo_log='OTP', extra_info="Generando OTP automático con PUSHTAN")
        challenge_id, otp_code = client.generar_challenge_otp(payment_id, token, "PUSHTAN")
        
        # 5. Preparar datos de transferencia usando la estructura del modelo
        transfer_data = transfer.to_schema_data()
        # Agregar payment_id y status que no están en to_schema_data()
        transfer_data.update({
            "payment_id": payment_id,
            "status": "PDNG"
        })
        
        # 6. Enviar transferencia con certificados SSL
        registrar_log(payment_id, tipo_log='TRANSFER', extra_info="Enviando transferencia con certificados SSL a Deutsche Bank")
        success, result = client.enviar_transferencia(payment_id, token, otp_code)
        
        if success:
            # 7. Actualizar estado de la transferencia
            if 'status' in result:
                transfer.status = result['status']
                transfer.save()
            
            # 8. Generar XML y AML usando recursos existentes
            try:
                xml_path = generar_xml_pain001(transfer, payment_id)
                aml_path = generar_archivo_aml(transfer, payment_id)
                registrar_log(payment_id, tipo_log='XML', extra_info=f"XML y AML generados: {xml_path}, {aml_path}")
            except Exception as e:
                registrar_log(payment_id, tipo_log='ERROR', error=str(e), extra_info="Error generando XML/AML")
            
            registrar_log(payment_id, tipo_log='TRANSFER', extra_info=f"Transferencia completada con estado: {result.get('status', 'UNKNOWN')}")
            return True, result
        else:
            registrar_log(payment_id, tipo_log='ERROR', error=result, extra_info="Error en transferencia con certificados SSL")
            return False, result
            
    except Transfer.DoesNotExist:
        error_msg = f"Transferencia {payment_id} no encontrada en la base de datos"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, error_msg
    except Exception as e:
        error_msg = f"Error inesperado: {str(e)}"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, error_msg


def enviar_transferencia_con_pushtan(payment_id: str, token: str, psu_ip_address: Optional[str] = None):
    """
    Envía transferencia usando certificados SSL y PUSHTAN automático.
    No requiere intervención del usuario para el OTP.
    
    Args:
        payment_id: ID de la transferencia
        token: Token de autenticación obtenido con certificados
    
    Returns:
        tuple: (success: bool, result: dict)
    """
    try:
        # 1. Obtener la transferencia
        transfer = Transfer.objects.get(payment_id=payment_id)
        
        # 2. Crear cliente con certificados SSL
        client = DeutscheBankClient()
        
        # 3. Preparar datos según esquema SEPA
        transfer_data = transfer.to_schema_data()
        
        # 4. Construir URL completa para transferencia SEPA
        base_url = client.base_url
        sepa_path = "/gw/dbapi/banking/transactions/v2"
        url = f"{base_url}{sepa_path}"
        
        # 5. Headers según especificación Deutsche Bank con PUSHTAN
        headers = default_request_headers().copy()
        headers.update({
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "idempotency-Id": payment_id,
            "otp": "PUSHTAN",
            "Correlation-Id": payment_id,
        })
        
        # 6. Payload completo según esquema SEPA
        payload = {
            "purposeCode": transfer_data.get("purposeCode"),
            "requestedExecutionDate": transfer_data.get("requestedExecutionDate"),
            "debtor": {
                "debtorName": transfer_data["debtor"]["debtorName"]
            },
            "debtorAccount": {
                "iban": transfer_data["debtorAccount"]["iban"],
                "currency": transfer_data["debtorAccount"].get("currency", "EUR")
            },
            "paymentIdentification": {
                "endToEndIdentification": transfer_data["paymentIdentification"]["endToEndId"],
                "instructionId": transfer_data["paymentIdentification"].get("instructionId")
            },
            "instructedAmount": {
                "amount": float(transfer_data["instructedAmount"]["amount"]),
                "currency": transfer_data["instructedAmount"]["currency"]
            },
            "creditorAgent": {
                "financialInstitutionId": transfer_data.get("creditorAgent", {}).get("financialInstitutionId")
            },
            "creditor": {
                "creditorName": transfer_data["creditor"]["creditorName"]
            },
            "creditorAccount": {
                "iban": transfer_data["creditorAccount"]["iban"],
                "currency": transfer_data["creditorAccount"].get("currency", "EUR")
            },
            "remittanceInformationUnstructured": transfer_data.get("remittanceInformationUnstructured")
        }
        
        # 7. Log de inicio
        registrar_log(
            payment_id,
            tipo_log='TRANSFER',
            headers_enviados=headers,
            request_body=payload,
            extra_info="Enviando transferencia SEPA con PUSHTAN automático"
        )
        
        # 8. Crear sesión SSL y enviar
        session = client._create_session()
        response = session.post(url, json=payload, headers=headers, timeout=30)
        if response.status_code == 404 and client.alt_base_url:
            alt_url = f"{client.alt_base_url}{sepa_path}"
            logger.warning(f"404 en {url}. Reintentando con {alt_url}")
            response = session.post(alt_url, json=payload, headers=headers, timeout=30)
        
        # 9. Log de respuesta
        registrar_log(
            payment_id,
            tipo_log='TRANSFER',
            response_headers=dict(response.headers),
            response_text=response.text,
            extra_info=f"Respuesta recibida. Status code: {response.status_code}"
        )
        
        # 10. Verificar respuesta
        if response.status_code == 201:
            # Éxito
            data = response.json()
            
            # La respuesta debe contener según el esquema:
            # - transactionStatus: ACCP, PDNG, etc.
            # - paymentId: ID de la transacción
            # - authId: ID de autorización
            
            transaction_status = data.get("transactionStatus", "UNKNOWN")
            auth_id = data.get("authId")
            
            registrar_log(
                payment_id,
                tipo_log='SUCCESS',
                extra_info=f"✅ Transferencia exitosa. Status: {transaction_status}, AuthID: {auth_id}"
            )
            
            # Actualizar el modelo
            transfer.status = transaction_status
            if auth_id:
                transfer.auth_id = auth_id
            transfer.save()
            
            # Generar documentos de auditoría
            try:
                from api.gpt4.utils import generar_xml_pain001, generar_archivo_aml
                xml_path = generar_xml_pain001(transfer, payment_id)
                aml_path = generar_archivo_aml(transfer, payment_id)
                
                registrar_log(
                    payment_id,
                    tipo_log='DOCUMENTS',
                    extra_info=f"Documentos generados: XML={xml_path}, AML={aml_path}"
                )
            except Exception as doc_error:
                registrar_log(
                    payment_id,
                    tipo_log='WARNING',
                    error=str(doc_error),
                    extra_info="Error generando documentos (no crítico)"
                )
            
            return True, data
            
        elif response.status_code == 400:
            # Error de validación
            error_data = response.json()
            error_code = error_data.get("code")
            error_message = error_data.get("message")
            
            # Códigos de error específicos según el JSON
            error_messages = {
                6502: "Solo se acepta moneda EUR",
                6515: "IBAN de origen inválido",
                6517: "Solo se acepta EUR en cuenta destino",
                6519: "Fecha de ejecución no puede ser mayor a 90 días",
                6524: "Límite diario alcanzado",
                17: "OTP inválido - verificar configuración PUSHTAN"
            }
            
            detailed_error = error_messages.get(error_code, error_message)
            
            registrar_log(
                payment_id,
                tipo_log='ERROR',
                error=f"Código {error_code}: {detailed_error}",
                extra_info="Error de validación en transferencia"
            )
            
            return False, detailed_error
            
        elif response.status_code == 401:
            # Error de autenticación
            registrar_log(
                payment_id,
                tipo_log='ERROR',
                error="Token inválido o expirado",
                extra_info="Se requiere reautenticación"
            )
            return False, "Error de autenticación - token inválido o expirado"
            
        elif response.status_code == 409:
            # Conflicto - ID duplicado
            registrar_log(
                payment_id,
                tipo_log='ERROR',
                error="Transferencia duplicada",
                extra_info="El idempotency-Id ya fue utilizado"
            )
            return False, "Transferencia duplicada - esta operación ya fue procesada"
            
        else:
            # Otros errores
            registrar_log(
                payment_id,
                tipo_log='ERROR',
                error=f"Status code: {response.status_code}",
                response_text=response.text,
                extra_info="Error inesperado en transferencia"
            )
            return False, f"Error del servidor: {response.status_code}"
            
    except Transfer.DoesNotExist:
        error_msg = f"Transferencia {payment_id} no encontrada"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, error_msg
        
    except requests.exceptions.SSLError as e:
        error_msg = f"Error SSL: {str(e)}"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, "Error de certificado SSL - verificar configuración"
        
    except requests.exceptions.Timeout:
        error_msg = "Timeout en la conexión con el banco"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, error_msg
        
    except Exception as e:
        error_msg = f"Error inesperado: {str(e)}"
        registrar_log(payment_id, tipo_log='ERROR', error=error_msg)
        return False, error_msg


def verificar_estado_transferencia_pushtan(payment_id: str, token: str):
    """
    Verifica el estado de una transferencia enviada con PUSHTAN.
    
    Args:
        payment_id: ID de la transferencia
        token: Token de autenticación
    
    Returns:
        dict: Estado actual de la transferencia
    """
    try:
        client = DeutscheBankClient()
        
        # URL para consultar estado
        status_path = f"/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer/{payment_id}/status"
        url = f"{client.base_url}{status_path}"
        
        headers = {
            "Authorization": f"Bearer {token}",
            "Correlation-Id": payment_id
        }
        
        session = client._create_session()
        response = session.get(url, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            return {
                "success": True,
                "status": data.get("transactionStatus"),
                "payment_id": data.get("paymentId"),
                "auth_id": data.get("authId")
            }
        else:
            return {
                "success": False,
                "error": f"Error obteniendo estado: {response.status_code}"
            }
            
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }



def obtener_token_deutsche_bank(username: str, password: str):
    """
    Obtiene token de Deutsche Bank usando certificados SSL.
    """
    client = DeutscheBankClient()
    return client.obtener_token(username, password)

def enviar_transferencia_deutsche_bank(payment_id: str, token: str, username: str, password: str):
    """
    Envía transferencia a Deutsche Bank usando certificados SSL y OTP automático.
    """
    client = DeutscheBankClient()
    return client.enviar_transferencia(payment_id, token)

# ============================================================================
# FUNCIONES DE INTEGRACIÓN CON CONEXION_BANCO.PY
# ============================================================================

def make_request_deutsche_bank(method: str, path: str, token: str = None, payload: dict = None):
    """
    Versión de make_request que usa certificados SSL para Deutsche Bank.
    Integra con la función make_request existente pero usa certificados SSL.
    """
    try:
        client = DeutscheBankClient()
        
        # Normalizar path
        if not path.startswith("/"):
            path = "/" + path
        
        url = f"{client.base_url}{path}"
        
        headers = {}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        
        registrar_log("DEUTSCHE_BANK", tipo_log='REQUEST', extra_info=f"{method} {url}")
        
        session = client._create_session()
        response = session.request(
            method.upper(),
            url,
            json=payload,
            headers=headers,
            timeout=30
        )
        
        response.raise_for_status()
        registrar_log("DEUTSCHE_BANK", tipo_log='RESPONSE', extra_info=f"✅ {method} {path} → {response.status_code}")
        
        return response
        
    except Exception as e:
        registrar_log("DEUTSCHE_BANK", tipo_log='ERROR', error=str(e), extra_info=f"Error en make_request_deutsche_bank")
        raise

# ============================================================================
# FUNCIONES DE CONVENIENCIA PARA VISTAS EXISTENTES
# ============================================================================

def enviar_transferencia_con_certificados_desde_vista(payment_id: str, request):
    """
    Función para usar desde las vistas existentes.
    Obtiene credenciales del request o configuración.
    """
    try:
        # Obtener credenciales del request o configuración
        username = request.POST.get('username') or get_conf("BANK_USER")
        password = request.POST.get('password') or get_conf("BANK_PASS")
        
        if not username or not password:
            return False, "Credenciales de banco no configuradas"
        
        return enviar_transferencia_con_certificados(payment_id, username, password)
        
    except Exception as e:
        return False, f"Error: {str(e)}"

def verificar_certificados_disponibles():
    """
    Verifica que los certificados SSL estén disponibles.
    """
    try:
        from api.configuraciones_api.helpers import get_conf
        ruta_cert = get_conf("BASE_DIR")
        certs_dir = os.path.join(ruta_cert, 'deutsche_bank_certs')

        cert_path = os.path.join(certs_dir, 'deutsche_bank_certificate.pem')
        key_path = os.path.join(certs_dir, 'deutsche_bank_private_key.pem')
        ca_cert = os.path.join(certs_dir, 'ca-bundle-custom.pem')
        
        if not os.path.exists(cert_path):
            return False, f"Certificado no encontrado: {cert_path}"
        if not os.path.exists(key_path):
            return False, f"Clave privada no encontrada: {key_path}"
        if not os.path.exists(ca_cert):
            return False, f"Certificado de CA no encontrado: {ca_cert}"
        
        return True, "Certificados disponibles"
        
    except Exception as e:
        return False, f"Error verificando certificados: {str(e)}"

def diagnosticar_conexion_ssl():
    """
    Función de diagnóstico mejorada.
    """
    try:
        # 1. Verificar certificados
        certs_ok, cert_msg = verificar_certificados_disponibles()
        print(f"✅ Certificados: {cert_msg}")
        
        if not certs_ok:
            return False, cert_msg
        
        # 2. Probar conectividad básica
        print("🔍 Probando conectividad TCP a 193.150.166.1:443...")
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(10)
            sock.connect(('193.150.166.1', 443))
            sock.close()
            print("✅ Conectividad TCP exitosa")
        except Exception as e:
            print(f"❌ Error de conectividad: {e}")
            return False, f"Error de conectividad: {str(e)}"
        
        # 3. Probar conexión SSL
        print("🔍 Probando handshake SSL...")
        try:
            client = DeutscheBankClient()
            if client.test_connection():
                print("✅ Handshake SSL exitoso")
                return True, "Conexión SSL funcionando correctamente"
            else:
                print("❌ Falló handshake SSL (el método devolvió False)")
                return False, "Error en handshake SSL (método test_connection devolvió False)"
        except ssl.SSLError as e:
            print(f"❌ Error SSL en handshake: {e}")
            return False, f"Error SSL en handshake: {str(e)}"
        except Exception as e:
            print(f"❌ Error en prueba SSL: {e}")
            return False, f"Error en prueba SSL: {str(e)}"
            
    except Exception as e:
        error_msg = f"Error en diagnóstico: {str(e)}"
        print(f"❌ {error_msg}")
        return False, error_msg