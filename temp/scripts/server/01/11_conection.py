#!/usr/bin/env python3
import os
import socket
import paramiko

SSH_HOST = '193.150.166.1'
SSH_PORT = 443
USERNAME = '493069k1'
PASSWORD = '02569S'
REMOTE_DIR = os.path.dirname(os.path.abspath(__file__))


def main():
    xml_files = [f for f in os.listdir('.') if f.lower().endswith('.xml')]
    if not xml_files:
        print('No se encontraron archivos XML en el directorio actual')
        return

    for i, filename in enumerate(xml_files, 1):
        print(f'{i}. {filename}')
    try:
        choice = int(input('Selecciona el número del archivo a enviar: '))
        filename = xml_files[choice - 1]
    except (ValueError, IndexError):
        print('Selección no válida')
        return

    local_path = os.path.join(os.getcwd(), filename)
    remote_path = os.path.join(REMOTE_DIR, filename)

    try:
        transport = paramiko.Transport((SSH_HOST, SSH_PORT))
        transport.banner_timeout = 200
        transport.auth_timeout = 60
        transport.connect(username=USERNAME, password=PASSWORD)

        sftp = paramiko.SFTPClient.from_transport(transport)
        sftp.put(local_path, remote_path)
        sftp.close()
        transport.close()

        print(f"Archivo '{filename}' enviado correctamente a {remote_path}")
    except (paramiko.SSHException, socket.error) as e:
        print(f"No se pudo establecer la conexión SSH/SFTP: {e}")
    except Exception as e:
        print(f"No se pudo enviar el archivo: {e}")

if __name__ == '__main__':
    main()