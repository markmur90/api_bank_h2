
import datetime
import json
import os

from api.gpt4.models import LogTransferencia
from api.gpt4.utils import GLOBAL_LOG_FILE, obtener_ruta_schema_transferencia


def registrar_log(
    registro: str,
    tipo_log: str = 'TRANSFER',
    headers_enviados: dict = None,
    request_body: any = None,
    response_headers: dict = None,
    response_text: str = None,
    error: any = None,
    extra_info: str = None
):

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = "\n" + "=" * 80 + "\n"
    entry += f"Fecha y hora: {timestamp}\n" + "=" * 80 + "\n"

    if extra_info:
        entry += f"=== Info ===\n{extra_info}\n\n"
    if headers_enviados:
        try:
            entry += "=== Headers enviados ===\n" + json.dumps(headers_enviados, indent=4) + "\n\n"
        except Exception:
            entry += "=== Headers enviados (sin formato) ===\n" + str(headers_enviados) + "\n\n"
    if request_body:
        try:
            entry += "=== Body de la petición ===\n" + json.dumps(request_body, indent=4, default=str) + "\n\n"
        except Exception:
            entry += "=== Body de la petición (sin formato) ===\n" + str(request_body) + "\n\n"
    if response_headers:
        try:
            entry += "=== Response Headers ===\n" + json.dumps(response_headers, indent=4) + "\n\n"
        except Exception:
            entry += "=== Response Headers (sin formato) ===\n" + str(response_headers) + "\n\n"
    if response_text:
        entry += "=== Respuesta ===\n" + str(response_text) + "\n\n"
    if error:
        entry += "=== Error ===\n" + str(error) + "\n"

    carpeta = obtener_ruta_schema_transferencia(registro)
    log_path = os.path.join(carpeta, f"transferencia_{registro}.log")
    try:
        with open(log_path, 'a', encoding='utf-8') as f:
            f.write(entry)
    except Exception as e:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR AL GUARDAR EN ARCHIVO {registro}.log: {str(e)}\n")

    try:
        LogTransferencia.objects.create(
            registro=registro,
            tipo_log=tipo_log or 'ERROR',
            contenido=entry
        )
    except Exception as e:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR AL GUARDAR LOG EN DB para {registro}: {str(e)}\n")

    if error:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as gf:
            gf.write(f"[{timestamp}] ERROR [{registro}]: {str(error)}\n")