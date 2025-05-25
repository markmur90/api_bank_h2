from datetime import datetime
import os

def registrar_log(mensaje):
    fecha = datetime.now().strftime("%Y-%m-%d")
    hora = datetime.now().strftime("%H:%M:%S")
    carpeta = "logs/conexiones"
    os.makedirs(carpeta, exist_ok=True)
    ruta = f"{carpeta}/conexion_{fecha}.log"
    with open(ruta, "a") as f:
        f.write(f"[{hora}] {mensaje}\n")
