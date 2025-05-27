import os
import time
import uuid
import json
import logging
import random
import string
import hashlib
import base64
from django.http import JsonResponse
import requests
import xml.etree.ElementTree as ET
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from django.shortcuts import get_object_or_404
from jsonschema import validate
from lxml import etree
from reportlab.lib.pagesizes import letter
from reportlab.platypus import Table, TableStyle
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
import jwt
from cryptography.hazmat.primitives import serialization
from django.shortcuts import render, redirect, get_object_or_404
from django.http import FileResponse, HttpResponse, JsonResponse
from django.contrib import messages
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.template.loader import get_template
from weasyprint import HTML
from django.views.decorators.http import require_POST

from api.gpt4.models import LogTransferencia, Transfer
from api.gpt4.utils import generar_xml_pain002, handle_error_response, validar_xml_con_xsd
from api.gpt4.utils_core import load_private_key_y_kid
from config import settings
from config.settings.base1 import TIMEOUT_REQUEST




# ==== Directorios de schemas y logs ====
BASE_SCHEMA_DIR = os.path.join("schemas", "transferencias")
os.makedirs(BASE_SCHEMA_DIR, exist_ok=True)
TRANSFER_LOG_DIR = BASE_SCHEMA_DIR  # logs por transferencia
GLOBAL_LOG_FILE = os.path.join(TRANSFER_LOG_DIR, 'global_errors.log')

# ==== Configuración general ====
ORIGIN = settings.ORIGIN
CLIENT_ID = settings.CLIENT_ID
CLIENT_SECRET = settings.CLIENT_SECRET
TOKEN_URL = settings.TOKEN_URL
AUTH_URL = settings.AUTH_URL
API_URL = settings.API_URL

logger = logging.getLogger(__name__)


def obtener_ruta_schema_transferencia(payment_id: str) -> str:
    carpeta = os.path.join(BASE_SCHEMA_DIR, str(payment_id))
    os.makedirs(carpeta, exist_ok=True)
    return carpeta

def registrar_log_oauth(accion, estado, metadata=None, error=None, request=None):
    log_entry = {
        'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'accion': accion,
        'estado': estado,
        'metadata': metadata or {},
        'error': error
    }
    entry = json.dumps(log_entry, indent=2)

    log_dir = os.path.join(BASE_SCHEMA_DIR, "OAUTH_LOGS")
    os.makedirs(log_dir, exist_ok=True)
    log_file = os.path.join(log_dir, "oauth_general.log")

    session_id = None
    if request and hasattr(request, 'session'):
        session_id = request.session.session_key

    session_log_file = os.path.join(log_dir, f"oauth_general.log") if session_id else None

    try:
        with open(log_file, 'a') as f:
            f.write(entry + "\n")
        if session_log_file:
            with open(session_log_file, 'a') as f:
                f.write(entry + "\n")
    except Exception as e:
        print(f"Error escribiendo logs OAuth: {str(e)}")

    registro = request.session.get('current_payment_id') if request and hasattr(request, 'session') else None
    if not registro:
        registro = session_id or "SIN_SESION"

    try:
        LogTransferencia.objects.create(
            registro=registro,
            tipo_log='AUTH',
            contenido=entry
        )
    except Exception as e:
        with open(GLOBAL_LOG_FILE, 'a', encoding='utf-8') as f:
            f.write(f"[{datetime.now()}] Error guardando log OAuth en DB: {str(e)}\n")

    registrar_log(
        registro=registro,
        tipo_log='AUTH',
        request_body=metadata,
        error=error,
        extra_info=f"OAuth: {accion} - {estado}"
    )


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
            
            
def get_oauth_logs(request):

    session_key = request.GET.get('session_key')
    if not session_key:
        return JsonResponse({'error': 'Session key required'}, status=400)

    archivo_path = os.path.join(BASE_SCHEMA_DIR, "oauth_logs", f"oauth_general.log")
    logs_archivo = []
    logs_bd = []

    if os.path.exists(archivo_path):
        try:
            with open(archivo_path, 'r') as f:
                logs_archivo = [json.loads(line) for line in f.readlines()]
        except Exception as e:
            logs_archivo = [f"Error leyendo archivo: {e}"]

    try:
        logs_bd_qs = LogTransferencia.objects.filter(registro=session_key).order_by('-created_at')
        logs_bd = [{
            "fecha": log.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            "tipo_log": log.tipo_log,
            "contenido": log.contenido
        } for log in logs_bd_qs]
    except Exception as e:
        logs_bd = [f"Error leyendo base de datos: {e}"]

    return JsonResponse({
        'session_key': session_key,
        'logs_archivo': logs_archivo,
        'logs_bd': logs_bd
    })
    
    

def get_access_token(payment_id: str = None, force_refresh: bool = False) -> str:
    """Client Credentials Grant"""
    registrar_log(payment_id, tipo_log='AUTH', extra_info="Obteniendo Access Token (Client Credentials)")
    data = {'grant_type': 'client_credentials', 'scope': settings.SCOPE}
    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    registrar_log(payment_id, tipo_log='AUTH', headers_enviados=headers, request_body=data)
    try:
        resp = requests.post(TOKEN_URL, data=data, auth=(CLIENT_ID, CLIENT_SECRET), timeout=TIMEOUT_REQUEST)
        registrar_log(payment_id, tipo_log='AUTH', response_text=resp.text)
        resp.raise_for_status()
    except Exception as e:
        err = str(e)
        registrar_log(payment_id, tipo_log='ERROR', error=err, extra_info="Error al obtener Access Token")
        raise
    token = resp.json().get('access_token')
    if not token:
        err = resp.json().get('error_description', 'Sin access_token en respuesta')
        registrar_log(payment_id, tipo_log='AUTH', error=err, extra_info="Token inválido recibido")
        raise Exception(f"Token inválido: {err}")
    registrar_log(payment_id, tipo_log='AUTH', extra_info="Token obtenido correctamente")
    return token

def get_access_token_jwt(payment_id: str, force_refresh: bool = False) -> str:
    """JWT Assertion Grant"""
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    registrar_log(payment_id, tipo_log='AUTH', extra_info="Obteniendo Access Token (JWT Assertion)")
    now = int(time.time())
    payload = {
        'iss': transfer.client.clientId,
        'sub': transfer.client.clientId,
        'aud': TOKEN_URL,
        'iat': now,
        'exp': now + 3600
    }
    private_key, kid = load_private_key_y_kid()
    assertion = jwt.encode(payload, private_key, algorithm='ES256', headers={'kid': kid})
    data = {
        'grant_type': 'client_credentials',
        'scope': settings.SCOPE,
        'client_assertion_type': 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        'client_assertion': assertion
    }
    registrar_log(payment_id, tipo_log='AUTH', request_body=data)
    try:
        resp = requests.post(TOKEN_URL, data=data, timeout=TIMEOUT_REQUEST)
        registrar_log(payment_id, tipo_log='AUTH', response_text=resp.text)
        resp.raise_for_status()
    except Exception as e:
        err = str(e)
        registrar_log(payment_id, tipo_log='ERROR', error=err, extra_info="Error obteniendo Access Token JWT")
        raise
    token = resp.json().get('access_token')
    if not token:
        err = resp.json().get('error_description', 'Sin access_token en respuesta')
        registrar_log(payment_id, tipo_log='AUTH', error=err, extra_info="Token JWT inválido")
        raise Exception(f"Token JWT inválido: {err}")
    registrar_log(payment_id, tipo_log='AUTH', extra_info="Token JWT obtenido correctamente")
    return token




def oauth2_authorize(request):
    try:
        payment_id = request.GET.get('payment_id')
        if not payment_id:
            registrar_log(tipo_log="ERROR", error="OAuth2 requiere un payment_id", extra_info="Falta payment_id en GET SIN_ID")
            messages.error(request, "Debes iniciar autorización desde una transferencia específica.")
            return redirect('dashboard')
        transfer = get_object_or_404(Transfer, payment_id=payment_id)
        verifier, challenge = generate_pkce_pair()
        state = uuid.uuid4().hex
        request.session.update({'pkce_verifier': verifier,'oauth_state': state,'oauth_in_progress': True,'oauth_start_time': time.time(),'current_payment_id': payment_id})
        auth_url = build_auth_url(state, challenge)
        registrar_log_oauth("inicio_autorizacion", "exito", {"state": state,"auth_url": auth_url,"code_challenge": challenge}, request=request)
        registrar_log(payment_id, tipo_log="AUTH", request_body={"verifier": verifier,"challenge": challenge,"state": state}, extra_info="Inicio del flujo OAuth2 desde transferencia")
        # return render(request, 'api/GPT4/oauth2_authorize.html', {'auth_url': auth_url})
        return render(request, 'api/GPT4/oauth2_authorize.html', {
            'auth_url': auth_url,
            'payment_id': payment_id,
        })

    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e),request=request)        
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_authorize SIN_ID")
        messages.error(request, f"Error iniciando autorización OAuth2: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': None})


            
def oauth2_callback(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"},request=request)
            messages.error(request, "No hay una autorización en progreso")
            return redirect('dashboard')
        request.session['oauth_in_progress'] = False
        error = request.GET.get('error')
        if error:
            error_desc = request.GET.get('error_description', '')
            registrar_log_oauth("callback", "fallo", {"error": error,"error_description": error_desc,"params": dict(request.GET)},request=request)
            messages.error(request, f"Error en autorización: {error} - {error_desc}")
            return render(request, 'api/GPT4/oauth2_callback.html')
        state = request.GET.get('state')
        session_state = request.session.get('oauth_state')
        if state != session_state:
            registrar_log_oauth("callback", "fallo", {"razon": "state_mismatch","state_recibido": state,"state_esperado": session_state},request=request)
            messages.error(request, "Error de seguridad: State mismatch")
            return render(request, 'api/GPT4/oauth2_callback.html')
        code = request.GET.get('code')
        verifier = request.session.pop('pkce_verifier', None)
        registrar_log_oauth("callback", "procesando", {"code": code, "state": state},request=request)
        access_token, refresh_token, expires = fetch_token_by_code(code, verifier)
        request.session.update({'access_token': access_token,'refresh_token': refresh_token,'token_expires': time.time() + expires,'oauth_success': True})
        registrar_log_oauth("obtencion_token", "exito", {"token_type": "Bearer","expires_in": expires,"scope": settings.OAUTH2['SCOPE']},request=request)
        messages.success(request, "Autorización completada exitosamente!")
        return render(request, 'api/GPT4/oauth2_callback.html')
    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e),request=request)
        request.session['oauth_success'] = False
        messages.error(request, f"Error en el proceso de autorización: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html')


# ==== OAUTH2 ====
def oauth2_authorizeA(request):
    try:
        payment_id = request.GET.get('payment_id')
        if not payment_id:
            registrar_log_oauth("inicio_autorizacion", "error", {"error": "Falta payment_id"}, "OAuth2 requiere un payment_id", request=request)
            registrar_log(registro="SIN_ID", tipo_log="ERROR", error="OAuth2 requiere un payment_id", extra_info="Falta payment_id en GET")
            messages.error(request, "Debes iniciar autorización desde una transferencia específica.")
            return redirect('dashboard')

        transfer = get_object_or_404(Transfer, payment_id=payment_id)
        verifier, challenge = generate_pkce_pair()
        state = uuid.uuid4().hex
        request.session.update({
            'pkce_verifier': verifier,
            'oauth_state': state,
            'oauth_in_progress': True,
            'oauth_start_time': time.time(),
            'current_payment_id': payment_id
        })

        auth_url = build_auth_url(state, challenge)

        registrar_log_oauth("inicio_autorizacion", "exito", {
            "state": state,
            "auth_url": auth_url,
            "code_challenge": challenge
        }, request=request)

        registrar_log(payment_id, tipo_log="AUTH", request_body={
            "verifier": verifier,
            "challenge": challenge,
            "state": state
        }, extra_info="Inicio del flujo OAuth2 desde transferencia")

        return render(request, 'api/GPT4/oauth2_authorize.html', {
            'auth_url': auth_url,
            'payment_id': payment_id,
        })

    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e), request=request)
        registrar_log(registro="SIN_ID", tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_authorize")
        messages.error(request, f"Error iniciando autorización OAuth2: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': None})

def oauth2_callbackA(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"}, request=request)
            registrar_log("SIN_ID", tipo_log="ERROR", error="Flujo OAuth no iniciado", extra_info="callback sin sesión válida")
            messages.error(request, "No hay una autorización en progreso")
            return redirect('dashboard')

        request.session['oauth_in_progress'] = False
        error = request.GET.get('error')

        if error:
            error_desc = request.GET.get('error_description', '')
            registrar_log_oauth("callback", "fallo", {
                "error": error,
                "error_description": error_desc,
                "params": dict(request.GET)
            }, request=request)
            registrar_log("SIN_ID", tipo_log="ERROR", error=f"{error} - {error_desc}", extra_info="Error en callback OAuth")
            messages.error(request, f"Error en autorización: {error} - {error_desc}")
            return render(request, 'api/GPT4/oauth2_callback.html')

        state = request.GET.get('state')
        session_state = request.session.get('oauth_state')

        if state != session_state:
            registrar_log_oauth("callback", "fallo", {
                "razon": "state_mismatch",
                "state_recibido": state,
                "state_esperado": session_state
            }, request=request)
            registrar_log("SIN_ID", tipo_log="ERROR", error="State mismatch en OAuth callback", extra_info=f"Recibido: {state} / Esperado: {session_state}")
            messages.error(request, "Error de seguridad: State mismatch")
            return render(request, 'api/GPT4/oauth2_callback.html')

        code = request.GET.get('code')
        verifier = request.session.pop('pkce_verifier', None)

        registrar_log_oauth("callback", "procesando", {
            "code": code,
            "state": state
        }, request=request)

        access_token, refresh_token, expires = fetch_token_by_code(code, verifier)

        request.session.update({
            'access_token': access_token,
            'refresh_token': refresh_token,
            'token_expires': time.time() + expires,
            'oauth_success': True
        })

        registrar_log_oauth("obtencion_token", "exito", {
            "token_type": "Bearer",
            "expires_in": expires,
            "scope": settings.OAUTH2['SCOPE']
        }, request=request)

        registrar_log(request.session.get('current_payment_id', "SIN_ID"), tipo_log='AUTH', extra_info="Token OAuth2 almacenado en sesión exitosamente")

        messages.success(request, "Autorización completada exitosamente!")
        return render(request, 'api/GPT4/oauth2_callback.html')

    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e), request=request)
        registrar_log("SIN_ID", tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_callback")
        request.session['oauth_success'] = False
        messages.error(request, f"Error en el proceso de autorización: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html')


def oauth2_authorizeB(request):
    verifier, challenge = generate_pkce_pair()
    state = uuid.uuid4().hex
    request.session['pkce_verifier'] = verifier
    request.session['oauth_state'] = state
    return redirect(build_auth_url(state, challenge))

def oauth2_callbackB(request):
    error = request.GET.get('error')
    if error:
        messages.error(request, f"OAuth Error: {error}")
        return redirect('dashboard')
    code = request.GET.get('code')
    state = request.GET.get('state')
    if state != request.session.get('oauth_state'):
        messages.error(request, "State mismatch en OAuth2.")
        return redirect('dashboard')
    verifier = request.session.pop('pkce_verifier', None)
    access_token, refresh_token, expires = fetch_token_by_code(code, verifier)
    request.session['access_token'] = access_token
    request.session['refresh_token'] = refresh_token
    request.session['token_expires'] = time.time() + expires
    messages.success(request, "Autorización completada.")
    return redirect('dashboard')




def update_sca_request(transfer: Transfer, action: str, otp: str, token: str) -> requests.Response:
    url = f"{API_URL}/{transfer.payment_id}"
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Idempotency-Id': transfer.payment_id,
        'Correlation-Id': transfer.payment_id
    }
    payload = {'action': action, 'authId': transfer.auth_id}
    registrar_log(transfer.payment_id, tipo_log='SCA', headers_enviados=headers, request_body=payload, extra_info="Actualizando SCA")
    resp = requests.patch(url, headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
    registrar_log(transfer.payment_id, tipo_log='SCA', response_text=resp.text, extra_info="Respuesta SCA")
    resp.raise_for_status()
    data = resp.json()
    transfer.auth_id = data.get('authId')
    transfer.status = data.get('transactionStatus', transfer.status)
    transfer.save()
    return resp

def fetch_transfer_details(transfer: Transfer, token: str) -> dict:
    url = f"{API_URL}/{transfer.payment_id}"
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/json',
        'Idempotency-Id': transfer.payment_id,
        'Correlation-Id': transfer.payment_id
    }
    registrar_log(transfer.payment_id, tipo_log='TRANSFER', headers_enviados=headers, extra_info="Obteniendo estado de transferencia")
    resp = requests.get(url, headers=headers, timeout=TIMEOUT_REQUEST)
    registrar_log(transfer.payment_id, tipo_log='TRANSFER', response_text=resp.text, extra_info="Respuesta fetch status")
    resp.raise_for_status()
    data = resp.json()
    transfer.status = data.get('transactionStatus', transfer.status)
    transfer.save()
    # Generar pain002
    xml_path = generar_xml_pain002(data, transfer.payment_id)
    validar_xml_con_xsd(xml_path, xsd_path="schemas/xsd/pain.002.001.03.xsd")
    registrar_log(transfer.payment_id, tipo_log='TRANSFER', extra_info="Pain002 generado y validado")
    return data

def get_client_credentials_token():
    data = {
        'grant_type': 'client_credentials',
        'scope': settings.OAUTH2['SCOPE']
    }
    auth = (settings.OAUTH2['CLIENT_ID'], settings.OAUTH2['CLIENT_SECRET'])
    resp = requests.post(settings.OAUTH2['TOKEN_URL'], data=data, auth=auth, timeout=settings.OAUTH2['TIMEOUT'])
    resp.raise_for_status()
    return resp.json()['access_token'], resp.json().get('expires_in', 600)

def generate_pkce_pair():
    verifier = base64.urlsafe_b64encode(os.urandom(64)).rstrip(b'=').decode()
    challenge = base64.urlsafe_b64encode(
        hashlib.sha256(verifier.encode()).digest()
    ).rstrip(b'=').decode()
    return verifier, challenge

def build_auth_url(state, code_challenge):
    p = settings.OAUTH2
    return (
      f"{p['AUTHORIZE_URL']}?response_type=code"
      f"&client_id={p['CLIENT_ID']}"
      f"&redirect_uri={p['REDIRECT_URI']}"
      f"&scope={p['SCOPE']}"
      f"&state={state}"
      f"&code_challenge_method=S256"
      f"&code_challenge={code_challenge}"
    )

def fetch_token_by_code(code, code_verifier):
    p = settings.OAUTH2
    data = {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': p['REDIRECT_URI'],
      'code_verifier': code_verifier
    }
    auth = (p['CLIENT_ID'], p['CLIENT_SECRET'])
    resp = requests.post(p['TOKEN_URL'], data=data, auth=auth, timeout=p['TIMEOUT_REQUEST'])
    resp.raise_for_status()
    j = resp.json()
    return j['access_token'], j.get('refresh_token'), j.get('expires_in', 600)

def refresh_access_token(refresh_token: str) -> tuple[str,str,int]:
    p = settings.OAUTH2
    data = {
      'grant_type': 'refresh_token',
      'refresh_token': refresh_token
    }
    auth = (p['CLIENT_ID'], p['CLIENT_SECRET'])
    resp = requests.post(p['TOKEN_URL'], data=data, auth=auth, timeout=p['TIMEOUT_REQUEST'])
    resp.raise_for_status()
    j = resp.json()
    return j['access_token'], j.get('refresh_token'), j.get('expires_in', 600)


def crear_challenge_mtan(transfer: Transfer, token: str, payment_id: str) -> str:
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Idempotency-Id': payment_id,
        'Correlation-Id': payment_id
    }
    payload = {
        'method': 'MTAN',
        'requestType': 'SEPA_TRANSFER_GRANT',
        'challenge': {
            'mobilePhoneNumber': transfer.debtor.mobile_phone_number
        }
    }
    registrar_log(payment_id, headers_enviados=headers, request_body=payload, extra_info="Iniciando MTAN challenge", tipo_log='OTP')
    resp = requests.post(AUTH_URL, headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
    registrar_log(payment_id, response_text=resp.text, tipo_log='OTP')
    resp.raise_for_status()
    return resp.json()['id']

def verify_mtan(challenge_id: str, otp: str, token: str, payment_id: str) -> str:
    headers = {
      'Authorization': f'Bearer {token}',
      'Content-Type': 'application/json',
      'Correlation-Id': payment_id
    }
    payload = {'challengeResponse': otp}
    r = requests.patch(f"{AUTH_URL}/{challenge_id}", headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
    r.raise_for_status()
    return r.json()['challengeProofToken']

def crear_challenge_phototan(transfer: Transfer, token: str, payment_id: str):
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Idempotency-Id': payment_id,
        'Correlation-Id': payment_id
    }
    payload = {
        'method': 'PHOTOTAN',
        'requestType': 'SEPA_TRANSFER_GRANT',
        'challenge': {}
    }
    registrar_log(payment_id, headers_enviados=headers, request_body=payload, extra_info="Iniciando PhotoTAN challenge", tipo_log='OTP')
    resp = requests.post(AUTH_URL, headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
    registrar_log(payment_id, response_text=resp.text, tipo_log='OTP')
    resp.raise_for_status()
    data = resp.json()
    return data['id'], data.get('imageBase64')

def verify_phototan(challenge_id: str, otp: str, token: str, payment_id: str) -> str:
    # idéntico a verify_mtan
    return verify_mtan(challenge_id, otp, token, payment_id)



def resolver_challenge(challenge_id: str, token: str, payment_id: str) -> str:
    headers = {
        'Authorization': f'Bearer {token}',
        'Correlation-Id': payment_id
    }
    start = time.time()
    while True:
        resp = requests.get(f"{AUTH_URL}/{challenge_id}", headers=headers, timeout=TIMEOUT_REQUEST)
        registrar_log(payment_id, response_text=resp.text, extra_info=f"Comprobando estado challenge {challenge_id}", tipo_log='OTP')
        data = resp.json()
        status = data.get('status')
        if status == 'VALIDATED':
            otp = data.get('otp')
            registrar_log(payment_id, extra_info=f"OTP validado: {otp}", tipo_log='AUTH')
            return otp
        if status in ('EXPIRED', 'REJECTED', 'EIDP_ERROR'):
            msg = f"Challenge fallido: {status}"
            registrar_log(payment_id, error=msg, tipo_log='ERROR')
            raise Exception(msg)
        if time.time() - start > 300:
            msg = "Timeout esperando VALIDATED"
            registrar_log(payment_id, error=msg, tipo_log='ERROR')
            raise TimeoutError(msg)
        time.sleep(1)

def obtener_otp_automatico(transfer: Transfer):
    token = get_access_token(transfer.payment_id)
    challenge_id = crear_challenge_pushtan(transfer, token, transfer.payment_id)
    otp = resolver_challenge(challenge_id, token, transfer.payment_id)
    return otp, token

    
# ===========================
# OTP
# ===========================
def preparar_request_type_y_datos(schema_data):
    request_type = "SEPA_TRANSFER_GRANT"
    datos = {
        "type": "challengeRequestDataSepaPaymentTransfer",
        "targetIban": schema_data["creditorAccount"]["iban"],
        "amountCurrency": schema_data["instructedAmount"]["currency"],
        "amountValue": schema_data["instructedAmount"]["amount"]
    }
    return request_type, datos

def crear_challenge_pushtan(transfer: Transfer, token: str, payment_id: str) -> str:
    schema_data = transfer.to_schema_data()
    request_data = {
        "type": "challengeRequestDataSepaPaymentTransfer",
        "targetIban": schema_data["creditorAccount"]["iban"],
        "amountCurrency": schema_data["instructedAmount"]["currency"],
        "amountValue": schema_data["instructedAmount"]["amount"]
    }
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json',
        'Correlation-Id': payment_id
    }
    payload = {
        'method': 'PUSHTAN',
        'requestType': 'SEPA_TRANSFER_GRANT',
        'requestData': request_data,
        'language': 'de'
    }
    response = requests.post(AUTH_URL, headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
    response.raise_for_status()
    if response.status_code != 201:
        error_msg = handle_error_response(response)
        registrar_log(payment_id, headers, response.text, error=error_msg, tipo_log='ERROR')
        raise Exception(error_msg)
    return response.json()['id']

def crear_challenge_autorizacion(transfer, token):
    pid = transfer.payment_id
    try:
        registrar_log(pid, extra_info="Iniciando challenge OTP", tipo_log='OTP')
        payload = {
            'method':'PUSHTAN','requestType':'SEPA_TRANSFER_GRANT',
            'requestData':{
                'type':'challengeRequestDataSepaPaymentTransfer',
                'targetIban':transfer.creditor_account.iban,
                'amountCurrency':transfer.currency,
                'amountValue':float(transfer.instructed_amount)
            },'language':'de'
        }
        headers = {'Authorization':f'Bearer {token}','Content-Type':'application/json'}
        registrar_log(pid, headers_enviados=headers, request_body=payload, tipo_log='OTP')
        resp = requests.post(AUTH_URL, headers=headers, json=payload, timeout=TIMEOUT_REQUEST)
        registrar_log(pid, response_text=resp.text, tipo_log='OTP')
        resp.raise_for_status()
        cid = resp.json().get('id')
        registrar_log(pid, extra_info=f"Challenge creado con ID {cid}", tipo_log='OTP')
        return cid
    except Exception as e:
        registrar_log(pid, error=str(e), extra_info="Error al crear challenge", tipo_log='ERROR')
        raise

def resolver_challenge_pushtan(challenge_id: str, token: str, payment_id: str) -> str:
    headers = {
        'Authorization': f'Bearer {token}',
        'Correlation-Id': payment_id
    }
    start = time.time()
    while True:
        response = requests.get(f"{AUTH_URL}/{challenge_id}", headers=headers, timeout=10)
        data = response.json()
        status = data.get('status')
        if status == 'VALIDATED':
            return data['otp']
        if status == 'PENDING' and time.time() - start < 300:
            msg = "Timeout agotado esperando VALIDATED"
            registrar_log(payment_id, headers, error=msg, tipo_log='ERROR')
            raise TimeoutError(msg)
            time.sleep(1)
            continue
        elif status == "EXPIRED":
            msg = "El challenge ha expirado (status=EXPIRED)"
            registrar_log(payment_id, headers, response.text, error=msg, tipo_log='ERROR')
            raise Exception(msg)
        elif status == "REJECTED":
            msg = "El challenge fue rechazado por el usuario (status=REJECTED)"
            registrar_log(payment_id, headers, response.text, error=msg, tipo_log='ERROR')
            raise Exception(msg)
        elif status == "EIDP_ERROR":
            msg = "Error interno de EIDP procesando el challenge (status=EIDP_ERROR)"
            registrar_log(payment_id, headers, response.text, error=msg, tipo_log='ERROR')
            raise Exception(msg)
        else:
            msg = f"Estado de challenge desconocido: {status}"
            registrar_log(payment_id, headers, response.text, error=msg, tipo_log='ERROR')
            raise Exception(msg)


def obtener_otp_automatico_con_challenge(transfer):
    token = get_access_token(transfer.payment_id)
    challenge_id = crear_challenge_autorizacion(transfer, token, transfer.payment_id)
    otp_token = resolver_challenge(challenge_id, token, transfer.payment_id)
    return otp_token, token
