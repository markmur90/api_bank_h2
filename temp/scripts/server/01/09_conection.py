#!/usr/bin/env python3
import os
import requests
import urllib3
from pathlib import Path

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

USER = "493069k1"
AUTHORIZATION_PIN = "02569S"
CFO_PIN = "54082"
SSN = "0211676"
CLIENT_NO = "000000000SRTRN38837862BEH1RLN000000"
DB_IDENTITY_CODE = "27C DB FR DE 17BEN"
TRANSACTION_ID = "090s12500700100958886479"
SERVER = "193.150.166.1"
PORT = "443"

payload = {
    "user": USER,
    "pin": AUTHORIZATION_PIN,
    "cfoPin": CFO_PIN,
    "ssn": SSN,
    "clientNo": CLIENT_NO,
    "dbIdentity": DB_IDENTITY_CODE,
    # "transactionId": TRANSACTION_ID
}

url = f"https://{SERVER}:{PORT}/api/login"
response = requests.post(url, json=payload, verify=False)

if response.status_code == 200:
    print("Conexión exitosa")
else:
    print(f"Error de conexión. Código HTTP: {response.status_code}")
    exit(1)
