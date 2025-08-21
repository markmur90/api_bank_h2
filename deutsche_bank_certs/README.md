# Certificados TLS para Deutsche Bank

Este directorio contiene certificados TLS personalizados para conectarse al servidor Deutsche Bank.

## �� Archivos generados:

- `deutsche_bank_private_key.pem` - Clave privada RSA de 4096 bits
- `deutsche_bank_certificate.pem` - Certificado autofirmado
- `deutsche_bank.csr` - Certificate Signing Request
- `deutsche_bank.p12` - Bundle PKCS#12 para aplicaciones
- `openssl.conf` - Configuración OpenSSL
- `openssl_commands.txt` - Comandos OpenSSL de referencia
- `deutsche_bank_client_example.py` - Ejemplo de cliente Python

## 🔧 Información del certificado:

- **País**: DE
- **Estado**: HESSE
- **Ciudad**: FRANKFURT
- **Organización**: DEUTSCHE BANK AG
- **Unidad Organizacional**: IT SECURITY
- **Nombre común**: 193.150.166.1
- **Email**: security@deutsche-bank.com
- **Validez**: 365 días
- **Tamaño de clave**: 4096 bits

## 🚀 Uso:

### Con Python:
```python
import ssl
import socket

context = ssl.create_default_context()
context.load_cert_chain('deutsche_bank_certificate.pem', 'deutsche_bank_private_key.pem')

with socket.create_connection(('193.150.166.1', 443)) as sock:
    with context.wrap_socket(sock) as ssock:
        # Tu código aquí
        pass
```

### Con OpenSSL:
```bash
openssl s_client -connect 193.150.166.1:443 -cert deutsche_bank_certificate.pem -key deutsche_bank_private_key.pem
```

### Con curl:
```bash
curl --cert deutsche_bank_certificate.pem --key deutsche_bank_private_key.pem https://193.150.166.1:443
```

## ⚠️ Notas importantes:

1. Este es un certificado autofirmado para propósitos de desarrollo/pruebas
2. Para producción, use certificados emitidos por una autoridad certificadora confiable
3. El certificado incluye Subject Alternative Names para compatibilidad
4. Compatible con TLS 1.3 y AES-256-GCM

## 🔒 Seguridad:

- Clave privada de 4096 bits
- Algoritmo de firma: SHA-256
- Extensión Key Usage configurada para autenticación de servidor y cliente
- Subject Alternative Names incluidos para múltiples dominios/IPs

Generado el: 2025-08-14 07:08:36
