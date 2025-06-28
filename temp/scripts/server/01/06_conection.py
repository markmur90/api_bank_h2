#!/usr/bin/env python3
import re
import time
import subprocess
import paramiko
import webbrowser
import requests
import xml.etree.ElementTree as ET
import os

VPN_SERVER="193.150.166.1"
VPN_USER="deutschebank@AS8373"
VPN_PIN="02569S"
VPN_CERT_HASH="pin-sha256:CsT9SNs04/jaKUayEsujXkLLmZQ40+dTcjN2oq1k/Sk="
SSH_PORT=443

API_URL="https://ebankingdb.db.com/api/auth"
API_HEADERS={"Content-Type":"application/xml","SOAPAction":"Authenticate"}
API_PAYLOAD_TEMPLATE="""
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:bnk="http://db.com/banking">
  <soapenv:Body>
    <bnk:Authenticate>
      <bnk:user>{user}</bnk:user>
      <bnk:pin>{pin}</bnk:pin>
      <bnk:ssn>{ssn}</bnk:ssn>
    </bnk:Authenticate>
  </soapenv:Body>
</soapenv:Envelope>
"""

TRANSFER_URL="https://ebankingdb.db.com/api/transfer"
TRANSFER_HEADERS={"Content-Type":"application/xml","SOAPAction":"DoTransfer"}

EBANKING_URL="https://ebankingdb.db.com/dashboard"

def connect_vpn():
    args=["openconnect", VPN_SERVER, "--user", VPN_USER, "--passwd-on-stdin", "--servercert", VPN_CERT_HASH]
    p=subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out,err=p.communicate(VPN_PIN+"\n")
    if p.returncode!=0:
        raise Exception(err.strip())

def connect_ssh():
    client=paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(VPN_SERVER, SSH_PORT, username=VPN_USER, password=VPN_PIN)
    chan=client.invoke_shell()
    time.sleep(1)
    chan.send("echo Conectado a SSH\n")
    time.sleep(1)
    print(chan.recv(1024).decode().strip())
    client.close()

def call_api(url, headers, payload):
    r=requests.post(url, data=payload, headers=headers, timeout=30)
    r.raise_for_status()
    print("=== XML de respuesta ===\n", r.text)
    return r.text

def extract_auth_token(xml_string):
    root=ET.fromstring(xml_string)
    m=re.match(r'\{(.+)\}', root.tag)
    ns=m.group(1) if m else ''
    tag=f'.//{{{ns}}}auth' if ns else './/auth'
    elem=root.find(tag)
    if elem is None or not elem.text:
        raise Exception(f"La respuesta XML no tiene nodo «auth» (buscado como «{tag}»)")
    return elem.text

def do_transfer(xml_string):
    return call_api(TRANSFER_URL, TRANSFER_HEADERS, xml_string)

def open_web(token):
    webbrowser.open(f"{EBANKING_URL}?token={token}")

def main():
    try:
        print("1) Conectando VPN…")
        connect_vpn()
        print("2) Túnel SSH establecido")
        connect_ssh()
        print("3) Autenticando en la API banking…")
        payload_auth=API_PAYLOAD_TEMPLATE.format(user=VPN_USER,pin=VPN_PIN,ssn="0211676")
        xml_auth=call_api(API_URL,API_HEADERS,payload_auth)
        token=extract_auth_token(xml_auth)
        print("Token obtenido:",token)
        print("4) Introduce el nombre del archivo XML de transferencia:")
        file_name=input().strip()
        path=os.path.join(os.path.dirname(__file__), file_name)
        with open(path, "r", encoding="utf-8") as f:
            transfer_xml=f.read()
        print("5) Ejecutando transferencia…")
        respuesta_transfer=do_transfer(transfer_xml)
        print("=== XML respuesta transferencia ===\n",respuesta_transfer)
        print("6) Abriendo e-banking…")
        open_web(token)
    except Exception as e:
        print("Error en el proceso:",e)

if __name__=="__main__":
    main()
