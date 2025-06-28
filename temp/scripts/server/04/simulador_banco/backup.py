import os
import shutil
from datetime import datetime

def crear_backup():
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    os.makedirs("backups", exist_ok=True)
    if os.path.exists("logs/conexiones"):
        destino = f"backups/logs_backup_{timestamp}"
        shutil.make_archive(destino, 'gztar', root_dir="logs/conexiones")
        print(f"Backup creado en {destino}.tar.gz")
    else:
        print("No hay logs que respaldar.")

if __name__ == "__main__":
    crear_backup()
