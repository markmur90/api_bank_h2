#!/usr/bin/env python3
import os
import ssl
import socket
import requests
from pathlib import Path

USER = "deutschebank@AS8373"
AUTHORIZATION_PIN = "02569S"
CFO_PIN = "54082"
SSN = "0211676"
CLIENT_NO = "000000000SRTRN38837862BEH1RLN000000"
DB_IDENTITY_CODE = "27C DB FR DE 17BEN"
TRANSACTION_ID = "090s12500700100958886479"
SERVER = "https://api.db.com:443/gw/dbapi/banking/transactions/v2"
# SERVER = "193.150.166.1"
PORT = "443"

payload = {
    "user": USER,
    "pin": AUTHORIZATION_PIN,
    "cfoPin": CFO_PIN,
    "ssn": SSN,
    "clientNo": CLIENT_NO,
    "dbIdentity": DB_IDENTITY_CODE,
    "transactionId": TRANSACTION_ID
}

hostname = SERVER
port = int(PORT)
context = ssl.create_default_context()
with socket.create_connection((hostname, port)) as sock:
    with context.wrap_socket(sock, server_hostname=hostname) as ssock:
        der_cert = ssock.getpeercert(True)
pem_cert = ssl.DER_cert_to_PEM_cert(der_cert)
SCRIPT_DIR = Path(__file__).resolve().parent
CERT_PATH = SCRIPT_DIR / "server_cert.pem"
with open(CERT_PATH, "w", encoding="utf-8") as f:
    f.write(pem_cert)
os.chmod(CERT_PATH, 0o644)

url = f"https://{SERVER}:{PORT}/api/login"
response = requests.post(url, json=payload, verify=str(CERT_PATH))

if response.status_code == 200:
    print("Conexión exitosa")
else:
    print(f"Error de conexión. Código HTTP: {response.status_code}")
    exit(1)
