#!/usr/bin/env python3
"""
Cliente Python de ejemplo para Deutsche Bank usando certificado TLS personalizado
"""

import ssl
import socket
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.ssl_ import create_urllib3_context

class DeutscheBankClient:
    def __init__(self, cert_path, key_path):
        self.cert_path = cert_path
        self.key_path = key_path
        
    def create_ssl_context(self):
        """Crea contexto SSL con certificado personalizado"""
        context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
        context.load_cert_chain(self.cert_path, self.key_path)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        return context
    
    def connect_with_socket(self, hostname="193.150.166.1", port=443):
        """Conecta usando socket con certificado personalizado"""
        try:
            context = self.create_ssl_context()
            
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    print(f"✅ Conexión exitosa a {hostname}:{port}")
                    print(f"🔒 Versión TLS: {ssock.version()}")
                    print(f"�� Cipher suite: {ssock.cipher()}")
                    
                    # Obtener certificado del servidor
                    cert = ssock.getpeercert()
                    print(f"📜 Certificado del servidor:")
                    print(f"   - Subject: {cert.get('subject', 'N/A')}")
                    print(f"   - Issuer: {cert.get('issuer', 'N/A')}")
                    
                    return True
                    
        except Exception as e:
            print(f"❌ Error de conexión: {e}")
            return False
    
    def connect_with_requests(self, url="https://193.150.166.1:443"):
        """Conecta usando requests con certificado personalizado"""
        try:
            session = requests.Session()
            
            # Configurar certificado
            session.cert = (self.cert_path, self.key_path)
            session.verify = False
            
            # Realizar request
            response = session.get(url, timeout=10)
            print(f"✅ Request exitoso: {response.status_code}")
            return response
            
        except Exception as e:
            print(f"❌ Error en request: {e}")
            return None

# Ejemplo de uso
if __name__ == "__main__":
    client = DeutscheBankClient(
        cert_path="deutsche_bank_certs/deutsche_bank_certificate.pem",
        key_path="deutsche_bank_certs/deutsche_bank_private_key.pem"
    )
    
    # Conectar usando socket
    client.connect_with_socket()
    
    # Conectar usando requests
    # client.connect_with_requests()
