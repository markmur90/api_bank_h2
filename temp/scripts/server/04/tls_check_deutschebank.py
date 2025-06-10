import ssl
import socket
from pprint import pprint

# Configuración del servidor ficticio
hostname = "ebankingdb.db.com1"
port = 443

# Crear contexto seguro
context = ssl.create_default_context()

with socket.create_connection((hostname, port)) as sock:
    with context.wrap_socket(sock, server_hostname=hostname) as ssock:
        print(f"Conectado a: {hostname}:{port}")
        print(f"Versión TLS: {ssock.version()}")
        print("\n📜 Certificado del servidor:")
        cert = ssock.getpeercert()
        pprint(cert)
