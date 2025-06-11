#!/usr/bin/env python3
import subprocess
import paramiko
import webbrowser
import time

IP_PRINCIPAL_DEL_SERVIDOR="193.150.166.1"
PUERTO_VPN="443"
USUARIO="deutschebank@AS8373"
PIN_AUTORIZACION="02569S"
SSN="0211676"
SERVERCERT="pin-sha256:CsT9SNs04/jaKUayEsujXkLLmZQ40+dTcjN2oq1k/Sk="
CLIENTE_VPN="openconnect"
PUERTO_SSH=443
DOMINIO_LOGIN="DEUBA"
URL_EBANKING="https://ebankingdb.db.com"

def connect_vpn():
    args=[CLIENTE_VPN, IP_PRINCIPAL_DEL_SERVIDOR, "--user", USUARIO, "--passwd-on-stdin", "--servercert", SERVERCERT]
    proc=subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out,err=proc.communicate(PIN_AUTORIZACION+"\n")
    if proc.returncode!=0:
        raise Exception(err.strip())

def connect_ssh():
    client=paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(IP_PRINCIPAL_DEL_SERVIDOR, PUERTO_SSH, username=USUARIO, password=PIN_AUTORIZACION)
    chan=client.invoke_shell()
    time.sleep(1)
    chan.send("echo Conectado a SSH\n")
    time.sleep(1)
    print(chan.recv(1024).decode().strip())
    client.close()

def open_web():
    webbrowser.open(URL_EBANKING)

def main():
    try:
        print("Iniciando VPN")
        connect_vpn()
        print("VPN establecida")
        print("Iniciando SSH")
        connect_ssh()
        print("SSH establecido")
        print("Abriendo e-banking")
        open_web()
    except Exception as e:
        print("Error en el proceso:", e)

if __name__=="__main__":
    main()
