
# ==== OAUTH2 ====
import base64
from datetime import time
import hashlib
import json
import os
from pyexpat.errors import messages
import secrets
from urllib.parse import urlencode
import uuid

from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
import requests
from api.gpt4.models import LogTransferencia, Transfer
from api.gpt4.registrarLog import registrar_log
from api.gpt4.utils import BASE_SCHEMA_DIR, registrar_log_oauth
from config import settings


def oauth2_authorize(request):
    try:
        payment_id = request.GET.get('payment_id')
        if not payment_id:
            registrar_log(payment_id, tipo_log="ERROR", error="OAuth2 requiere un payment_id", extra_info="Falta payment_id en GET SIN_ID")
            messages.error(request, "Debes iniciar autorización desde una transferencia específica.")
            return redirect('dashboard')
        transfer = get_object_or_404(Transfer, payment_id=payment_id)
        verifier, challenge = generate_pkce_pair()
        state = secrets.token_urlsafe(32)
        # state = uuid.uuid4().hex
        # request.session.update({'pkce_verifier': verifier,'oauth_state': state,'oauth_in_progress': True,'oauth_start_time': time.time(),'current_payment_id': payment_id})
        request.session.update({
            'pkce_verifier': verifier,
            'oauth_state': state,
            'oauth_in_progress': True,
            'oauth_start_time': time.time(),
            'current_payment_id': payment_id
        })
                
        auth_url = build_auth_url(state, challenge, redirect_uri=settings.OAUTH2['REDIRECT_URI'])
        registrar_log_oauth("inicio_autorizacion", "exito", {"state": state,"auth_url": auth_url,"code_challenge": challenge}, request=request)
        registrar_log(payment_id, tipo_log="AUTH", request_body={"verifier": verifier,"challenge": challenge,"state": state}, extra_info="Inicio del flujo OAuth2 desde transferencia")
        # return render(request, 'api/GPT4/oauth2_authorize.html', {'auth_url': auth_url})
        return redirect(auth_url)
    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e),request=request)        
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_authorize SIN_ID")
        messages.error(request, f"Error iniciando autorización OAuth2: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': None})

def oauth2_callback0(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"}, request=request)
            messages.error(request, "No hay una autorización en progreso")
            return redirect('dashboard')

        oauth_start = request.session.get('oauth_start_time')
        if not oauth_start or (time.time() - oauth_start > 3600):
            registrar_log_oauth("callback", "fallo", {"razon": "oauth_timeout", "start_time": oauth_start}, request=request)
            messages.error(request, "La sesión de autorización ha caducado. Por favor, inicia el proceso nuevamente.")
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
            messages.error(request, f"Error en autorización: {error} - {error_desc}")
            return render(request, 'api/GPT4/oauth2_callback.html')

        # state = request.GET.get('state')
        # session_state = request.session.get('oauth_state')

        # if state != session_state:
        #     registrar_log_oauth("callback", "fallo", {
        #         "razon": "state_mismatch",
        #         "state_recibido": state,
        #         "state_esperado": session_state
        #     }, request=request)
        #     messages.error(request, "Error de seguridad: State mismatch")
        #     return render(request, 'api/GPT4/oauth2_callback.html')
        state = request.GET.get('state')

        if time.time() - request.session.get('oauth_start_time', 0) > 3600:
            registrar_log_oauth("callback", "fallo", {"razon": "oauth_timeout"}, request=request)
            messages.error(request, "Sesión de autorización caducada. Intenta de nuevo.")
            return redirect('dashboard')

        session_state = request.session.get('oauth_state')

        if state != session_state:
            registrar_log_oauth("callback", "fallo", {
                "razon": "state_mismatch",
                "state_recibido": state,
                "state_esperado": session_state
            }, request=request)
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

        messages.success(request, "Autorización completada exitosamente!")
        return render(request, 'api/GPT4/oauth2_callback.html')

    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e), request=request)
        request.session['oauth_success'] = False
        messages.error(request, f"Error en el proceso de autorización: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html')

def oauth2_authorize1(request):
    try:
        # if not request.session.get('oauth_active', False):
        #     registrar_log_oauth("inicio_autorizacion", "fallo", {"razon": "oauth_inactivo"}, request=request)
        #     messages.error(request, "El flujo OAuth2 no está activado.")
        #     return redirect('dashboard')
        verifier, challenge = generate_pkce_pair()
        state = uuid.uuid4().hex
        request.session.update({'pkce_verifier': verifier,'oauth_state': state,'oauth_in_progress': True,'oauth_start_time': time.time()})
        auth_url = build_auth_url(state, challenge, redirect_uri=settings.OAUTH2['REDIRECT_URI'])
        registrar_log_oauth("inicio_autorizacion", "exito", {"state": state,"auth_url": auth_url,"code_challenge": challenge},request=request)
        return render(request, 'api/GPT4/oauth2_authorize.html', {'auth_url': auth_url})
    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e),request=request)
        messages.error(request, f"Error iniciando autorización OAuth2: {str(e)}")
        return redirect('dashboard')

def oauth2_callback(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"}, request=request)
            registrar_log(payment_id, tipo_log="ERROR", error="Flujo no iniciado", extra_info="oauth_in_progress ausente")
            messages.error(request, "No hay una autorización en curso.")
            return redirect('dashboard')
        request.session['oauth_in_progress'] = False
        error = request.GET.get('error')
        if error:
            desc = request.GET.get('error_description', '')
            registrar_log_oauth("callback", "fallo", {"error": error, "desc": desc}, request=request)
            registrar_log(payment_id, tipo_log="ERROR", error=error, extra_info=desc)
            messages.error(request, f"OAuth falló: {error} - {desc}")
            return render(request, 'api/GPT4/oauth2_callback.html')
        state = request.GET.get('state')
        expected = request.session.get('oauth_state')
        if state != expected:
            registrar_log_oauth("callback", "fallo", {"razon": "state_mismatch", "recibido": state, "esperado": expected}, request=request)
            registrar_log(payment_id, tipo_log="AUTH", error="State mismatch", extra_info=f"State recibido: {state}, esperado: {expected}")
            messages.error(request, "Error de seguridad: state inválido")
            return render(request, 'api/GPT4/oauth2_callback.html')
        payment_id = request.session.get('current_payment_id')
        if not payment_id:
            registrar_log_oauth("callback", "fallo", {"razon": "sin_payment_id"}, request=request)
            registrar_log(payment_id, tipo_log="AUTH", error="Falta payment_id", extra_info="OAuth sin contexto de transferencia")
            messages.error(request, "No se puede aplicar autorización: no se asoció a ninguna transferencia.")
            return redirect('dashboard')
        code = request.GET.get('code')
        verifier = request.session.pop('pkce_verifier', None)
        registrar_log_oauth("callback", "procesando", {"code": code, "state": state}, request=request)
        access_token, refresh_token, expires = fetch_token_by_code(code, verifier)
        request.session.update({'access_token': access_token,'refresh_token': refresh_token,'token_expires': time.time() + expires,'oauth_success': True})
        registrar_log_oauth("obtencion_token", "exito", {"expires_in": expires,"scope": settings.OAUTH2['SCOPE']}, request=request)
        registrar_log(payment_id, tipo_log="AUTH", request_body={"code": code,"verifier": verifier,"access_token": access_token,"refresh_token": refresh_token,"expires": expires}, extra_info="Token OAuth2 recibido y vinculado correctamente")
        messages.success(request, "Autorización completada para esta transferencia.")
        return render(request, 'api/GPT4/oauth2_callback.html')
    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e), request=request)
        registrar_log(payment_id, tipo_log="ERROR", error=str(e), extra_info="Excepción durante callback")
        request.session['oauth_success'] = False
        messages.error(request, f"Error en autorización: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html')

def oauth2_callback0(request):
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


def generate_pkce_pair():
    try:
        verifier = base64.urlsafe_b64encode(secrets.token_bytes(64)).rstrip(b'=').decode('utf-8')
        if not (43 <= len(verifier) <= 128):
            raise ValueError("El PKCE verifier debe tener entre 43 y 128 caracteres")
        challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b'=').decode('utf-8')
        registrar_log(tipo_log="AUTH", extra_info="PKCE generado", request_body={"verifier": verifier, "challenge": challenge})
        return verifier, challenge
    except Exception as e:
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Error generando PKCE pair")
        raise


def build_auth_url(state, challenge, redirect_uri):
    try:
        params = {
            'client_id': settings.OAUTH2['CLIENT_ID'],
            'response_type': 'code',
            'redirect_uri': redirect_uri,
            'code_challenge': challenge,
            'code_challenge_method': 'S256',
            'scope': settings.OAUTH2['SCOPE'],
            'state': state,
            'acr_values': 'urn:dbapi:psd2:sca'
        }
        url = f"{settings.OAUTH2['AUTH_URL']}?{urlencode(params)}"
        registrar_log(tipo_log="AUTH", extra_info="URL de autorización construida", request_body={"url": url})
        return url
    except Exception as e:
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Error construyendo URL de autorización")
        raise


def fetch_token_by_code(code, verifier):
    try:
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        data = {
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': settings.OAUTH2['REDIRECT_URI'],
            'code_verifier': verifier,
            'client_id': settings.OAUTH2['CLIENT_ID']
        }
        registrar_log(tipo_log="AUTH", extra_info="Solicitando token OAuth2", request_body=data)
        response = requests.post(settings.OAUTH2['TOKEN_URL'], data=data, headers=headers)
        registrar_log(tipo_log="AUTH", extra_info="Respuesta token OAuth2", request_body=data, response_body=response.text, response_headers=dict(response.headers))
        response.raise_for_status()
        token_data = response.json()
        return token_data['access_token'], token_data.get('refresh_token'), token_data['expires_in']
    except Exception as e:
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Error al obtener token OAuth2")
        raise


def oauth2_authorize0(request):
    try:
        payment_id = request.GET.get('payment_id')
        if not payment_id:
            registrar_log(tipo_log="ERROR", error="OAuth2 requiere un payment_id", extra_info="Falta payment_id en GET SIN_ID")
            messages.error(request, "Debes iniciar autorización desde una transferencia específica.")
            return redirect('dashboard')

        transfer = get_object_or_404(Transfer, payment_id=payment_id)

        verifier, challenge = generate_pkce_pair()
        state = secrets.token_urlsafe(32)

        request.session.update({
            'pkce_verifier': verifier,
            'oauth_state': state,
            'oauth_in_progress': True,
            'oauth_start_time': time.time(),
            'current_payment_id': payment_id
        })

        auth_url = build_auth_url(
            state=state,
            challenge=challenge,
            redirect_uri=settings.OAUTH2['REDIRECT_URI']
        )

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

        return redirect(auth_url)

    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e), request=request)
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_authorize SIN_ID")
        messages.error(request, f"Error iniciando autorización OAuth2: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': None})


def oauth2_callback0(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"}, request=request)
            messages.error(request, "No hay una autorización en progreso")
            return redirect('dashboard')

        oauth_start = request.session.get('oauth_start_time')
        if not oauth_start or (time.time() - oauth_start > 3600):
            registrar_log_oauth("callback", "fallo", {"razon": "oauth_timeout", "start_time": oauth_start}, request=request)
            messages.error(request, "La sesión de autorización ha caducado. Por favor, inicia el proceso nuevamente.")
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
            registrar_log(payment_id, tipo_log="ERROR", error=error, extra_info=error_desc)
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
            registrar_log(payment_id, tipo_log="AUTH", error="State mismatch", extra_info=f"State recibido: {state}, esperado: {session_state}")
            messages.error(request, "Error de seguridad: State mismatch")
            return render(request, 'api/GPT4/oauth2_callback.html')

        payment_id = request.session.get('current_payment_id')
        if not payment_id:
            registrar_log_oauth("callback", "fallo", {"razon": "sin_payment_id"}, request=request)
            registrar_log(payment_id, tipo_log="AUTH", error="Falta payment_id", extra_info="OAuth sin contexto de transferencia")
            messages.error(request, "No se puede aplicar autorización: no se asoció a ninguna transferencia.")
            return redirect('dashboard')

        code = request.GET.get('code')
        verifier = request.session.pop('pkce_verifier', None)

        if not code or not verifier:
            registrar_log_oauth("callback", "fallo", {
                "razon": "code_o_verifier_faltante",
                "code": code,
                "verifier": verifier
            }, request=request)
            messages.error(request, "Código de autorización o verificador inválidos.")
            return render(request, 'api/GPT4/oauth2_callback.html')

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

        registrar_log(tipo_log="INFO", extra_info="Token OAuth2 recibido y almacenado en sesión", request_body={"expires_in": expires})

        messages.success(request, "Autorización completada exitosamente!")
        return render(request, 'api/GPT4/oauth2_callback.html')

    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e), request=request)
        registrar_log(tipo_log="ERROR", error=str(e), extra_info="Excepción en oauth2_callback")
        request.session['oauth_success'] = False
        messages.error(request, f"Error en el proceso de autorización: {str(e)}")
        return render(request, 'api/GPT4/oauth2_callback.html')




def get_oauth_logs(request):

    session_key = request.GET.get('session_key')
    if not session_key:
        return JsonResponse({'error': 'Session key required'}, status=400)

    archivo_path = os.path.join(BASE_SCHEMA_DIR, "oauth_logs", f"oauth_session_{session_key}.log")
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
