#!/usr/bin/env python3
import subprocess
import paramiko
import webbrowser
import time

IP_PRINCIPAL_DEL_SERVIDOR="193.150.166.1"
PUERTO_DE_CONEXION=443
CLIENTE_VPN="openconnect"
# USUARIO="deutschebank@AS8373"
USUARIO="493069k1"
# PIN_AUTORIZACION="bar1588623"
# PIN_AUTORIZACION="edfr568760"
PIN_AUTORIZACION="02569S"
SSN="0211676"
DOMINIO_LOGIN="DEUBA"
URL_01="https://api.db.com"
URL_02="https://api.db.com:443/gw/dbapi/paymentInitiation/payments/v1/sepaCreditTransfer"
URL_EBANKING=URL_02


def connect_vpn():
    proc=subprocess.Popen([CLIENTE_VPN, IP_PRINCIPAL_DEL_SERVIDOR, "--user", USUARIO], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out_err=proc.communicate(PIN_AUTORIZACION+"\n")
    if proc.returncode!=0:
        raise Exception("VPN error: "+out_err[1])

def connect_ssh():
    client=paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(IP_PRINCIPAL_DEL_SERVIDOR, PUERTO_DE_CONEXION, USUARIO, PIN_AUTORIZACION)
    chan=client.invoke_shell()
    time.sleep(5)
    chan.send("echo Conectado a SSH\n")
    time.sleep(5)
    print(chan.recv(1024).decode())
    client.close()

def open_web():
    webbrowser.open(URL_EBANKING)

def main():
    try:
        print("Iniciando conexión VPN")
        connect_vpn()
        print("VPN conectada correctamente")
        print("Iniciando conexión SSH")
        connect_ssh()
        print("SSH conectado correctamente")
        print("Abriendo interfaz bancaria web")
        open_web()
    except Exception as e:
        print("Error en el proceso:", e)

if __name__=="__main__":
    main()
