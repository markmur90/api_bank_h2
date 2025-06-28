import socket
import dns.resolver
import paramiko
from paramiko.ssh_exception import SSHException
import requests
from requests.exceptions import RequestException
import ssl
from OpenSSL import crypto
import ipaddress

DNS_server_Domain='160.83.58.33'
Puerto_HTTPS=443
Host_SSH='193.150.166.1'
Usuario_de_acceso='deutschebank@AS8373'
PIN_de_autorizacion='02569S'
PIN_CFO='54082'
SSN='0211676'
Client_No='000000000SRTRN38837862BEH1RLN000000'
DB_Identity_Code='27C DB FR DE 17BEN'
Transaction_ID='090s12500700100958886479'

def test_dns():
    try:
        ipaddress.ip_address(DNS_server_Domain)
        return [DNS_server_Domain]
    except ValueError:
        respuesta=dns.resolver.resolve(DNS_server_Domain,'A')
        return [r.address for r in respuesta]

def test_port(host,port):
    s=socket.socket()
    s.settimeout(5)
    try:
        s.connect((host,port))
        s.close()
        return True
    except:
        return False

def test_ssh():
    cliente=paramiko.SSHClient()
    cliente.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        cliente.connect(
            Host_SSH,
            username=Usuario_de_acceso,
            password=PIN_de_autorizacion,
            timeout=5,
            banner_timeout=20
        )
        cliente.close()
        return True, None
    except SSHException as e:
        return False, f"SSHException: {e}"
    except Exception as e:
        return False, f"Error genérico: {e}"

def test_https():
    url=f'https://{DNS_server_Domain}'
    try:
        cert=ssl.get_server_certificate((DNS_server_Domain,Puerto_HTTPS))
        x509=crypto.load_certificate(crypto.FILETYPE_PEM,cert)
        subject=dict(x509.get_subject().get_components())
        r=requests.get(url,timeout=5,verify=True)
        return r.status_code, subject, None
    except RequestException as e:
        return None, None, f"RequestException: {e}"
    except ssl.SSLError as e:
        return None, None, f"SSLError: {e}"
    except Exception as e:
        return None, None, f"Error genérico: {e}"

def main():
    dns_ok=test_dns()
    puerto_https_ok=test_port(DNS_server_Domain,Puerto_HTTPS)
    puerto_ssh_ok=test_port(Host_SSH,22)
    ssh_ok, ssh_err=test_ssh()
    https_status, https_cert, https_err=test_https()
    print('Resultado de validación:')
    print('DNS Responde:', dns_ok)
    print('Puerto HTTPS abierto:', puerto_https_ok)
    print('Puerto SSH abierto:', puerto_ssh_ok)
    print('SSH Conexión exitosa:', ssh_ok, 
          ('; motivo: '+ssh_err) if ssh_err else '')
    print('HTTPS Status Code:', https_status, 
          ('; motivo: '+https_err) if https_err else '')
    print('HTTPS Certificado (Subject):', https_cert)

if __name__=='__main__':
    main()
