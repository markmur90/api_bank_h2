import ssl
import socket
import hashlib
from datetime import datetime
from logger import registrar_log
from alertas import enviar_alerta
from config import BANCO_HOST, BANCO_PORT, FINGERPRINT_VALIDO

def conectar_a_banco():
    contexto = ssl.create_default_context()
    with socket.create_connection((BANCO_HOST, BANCO_PORT)) as sock:
        with contexto.wrap_socket(sock, server_hostname=BANCO_HOST) as ssock:
            cert_bin = ssock.getpeercert(binary_form=True)
            fingerprint = ":".join(format(b, "02X") for b in hashlib.sha1(cert_bin).digest())
            tls = ssock.version()
            ip = ssock.getpeername()
            mensaje = f"Conexión TLS {tls} a {ip[0]}:{ip[1]}, Fingerprint: {fingerprint}"
            registrar_log(mensaje)

            if fingerprint != FINGERPRINT_VALIDO:
                alerta = f"ALERTA: Fingerprint inválido detectado: {fingerprint}"
                enviar_alerta("⚠️ Alerta de Seguridad TLS", alerta)
                registrar_log(alerta)
            else:
                registrar_log("Fingerprint verificado correctamente.")
