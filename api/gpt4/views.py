import json
import logging
import os
import time
import uuid
from django.shortcuts import render, redirect, get_object_or_404
from django.http import FileResponse, HttpResponse, JsonResponse
from django.contrib import messages
from django.core.paginator import Paginator, EmptyPage, PageNotAnInteger
from django.template.loader import get_template
from weasyprint import HTML
from django.views.decorators.http import require_POST

from api.gpt4.models import Debtor, DebtorAccount, Creditor, CreditorAccount, CreditorAgent, LogTransferencia, PaymentIdentification, Transfer
from api.gpt4.forms import ClientIDForm, DebtorForm, DebtorAccountForm, CreditorForm, CreditorAccountForm, CreditorAgentForm, KidForm, ScaForm, SendTransferForm, TransferForm
from api.gpt4.utils import BASE_SCHEMA_DIR, build_auth_url, crear_challenge_mtan, crear_challenge_phototan, crear_challenge_pushtan, fetch_token_by_code, fetch_transfer_details, generar_archivo_aml, generar_pdf_transferencia, generar_xml_pain001, generar_xml_pain002, generate_deterministic_id, generate_payment_id_uuid, generate_pkce_pair, get_access_token, get_client_credentials_token, handle_error_response, obtener_otp_automatico_con_challenge, obtener_ruta_schema_transferencia, read_log_file, refresh_access_token, registrar_log, registrar_log_oauth, resolver_challenge_pushtan, send_transfer, update_sca_request
from config import settings


logger = logging.getLogger(__name__)

# ==== DEBTOR ====
def create_debtor(request):
    if request.method == 'POST':
        form = DebtorForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('list_debtorsGPT4')
    else:
        form = DebtorForm()
    return render(request, 'api/GPT4/create_debtor.html', {'form': form})

def list_debtors(request):
    debtors = Debtor.objects.all()
    return render(request, 'api/GPT4/list_debtor.html', {'debtors': debtors})


# ==== DEBTOR ACCOUNT ====
def create_debtor_account(request):
    if request.method == 'POST':
        form = DebtorAccountForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('list_debtor_accountsGPT4')
    else:
        form = DebtorAccountForm()
    return render(request, 'api/GPT4/create_debtor_account.html', {'form': form})

def list_debtor_accounts(request):
    accounts = DebtorAccount.objects.all()
    return render(request, 'api/GPT4/list_debtor_accounts.html', {'accounts': accounts})


# ==== CREDITOR ====
def create_creditor(request):
    if request.method == 'POST':
        form = CreditorForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('list_creditorsGPT4')
    else:
        form = CreditorForm()
    return render(request, 'api/GPT4/create_creditor.html', {'form': form})

def list_creditors(request):
    creditors = Creditor.objects.all()
    return render(request, 'api/GPT4/list_creditors.html', {'creditors': creditors})


# ==== CREDITOR ACCOUNT ====
def create_creditor_account(request):
    if request.method == 'POST':
        form = CreditorAccountForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('list_creditor_accountsGPT4')
    else:
        form = CreditorAccountForm()
    return render(request, 'api/GPT4/create_creditor_account.html', {'form': form})

def list_creditor_accounts(request):
    accounts = CreditorAccount.objects.all()
    return render(request, 'api/GPT4/list_creditor_accounts.html', {'accounts': accounts})


# ==== CREDITOR AGENT ====
def create_creditor_agent(request):
    if request.method == 'POST':
        form = CreditorAgentForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('list_creditor_agentsGPT4')
    else:
        form = CreditorAgentForm()
    return render(request, 'api/GPT4/create_creditor_agent.html', {'form': form})

def list_creditor_agents(request):
    agents = CreditorAgent.objects.all()
    return render(request, 'api/GPT4/list_creditor_agents.html', {'agents': agents})


# ==== CLIENT ID ====
def create_clientid(request):
    if request.method == 'POST':
        form = ClientIDForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('create_transferGPT4')
    else:
        form = ClientIDForm()
    return render(request, 'api/GPT4/create_clientid.html', {'form': form})

# ==== KID ====
def create_kid(request):
    if request.method == 'POST':
        form = KidForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('create_transferGPT4')
    else:
        form = KidForm()
    return render(request, 'api/GPT4/create_kid.html', {'form': form})


# ==== TRANSFER ====
def create_transfer(request):
    if request.method == 'POST':
        form = TransferForm(request.POST)
        if form.is_valid():
            transfer = form.save(commit=False)
            transfer.payment_id = str(generate_payment_id_uuid())
            payment_identification = PaymentIdentification.objects.create(
                instruction_id=generate_deterministic_id(
                    transfer.payment_id,
                    transfer.creditor_account.iban,
                    transfer.instructed_amount
                ),
                end_to_end_id=generate_deterministic_id(
                    transfer.debtor_account.iban,
                    transfer.creditor_account.iban,
                    transfer.instructed_amount,
                    transfer.requested_execution_date,
                    prefix="E2E"
                )
            )
            transfer.payment_identification = payment_identification
            transfer.save()

            carpeta = obtener_ruta_schema_transferencia(transfer.payment_id)
            os.makedirs(carpeta, exist_ok=True)

            generar_xml_pain001(transfer, transfer.payment_id)
            generar_archivo_aml(transfer, transfer.payment_id)

            messages.success(request, "Transferencia creada y XML/AML generados correctamente.")
            return redirect('dashboard')
        else:
            messages.error(request, "Por favor corrige los errores en el formulario.")
    else:
        form = TransferForm()
    return render(request, 'api/GPT4/create_transfer.html', {'form': form, 'transfer': None})

def list_transfers(request):
    estado = request.GET.get("estado")
    transfers = Transfer.objects.all().order_by('-created_at')

    if estado in ["PNDG", "RJCT", "ACSP"]:
        transfers = transfers.filter(status=estado)

    paginator = Paginator(transfers, 10)
    page_number = request.GET.get('page', 1)
    try:
        transfers_paginated = paginator.page(page_number)
    except (EmptyPage, PageNotAnInteger):
        transfers_paginated = paginator.page(1)

    return render(request, 'api/GPT4/list_transfer.html', {
        'transfers': transfers_paginated
    })

def transfer_detail0(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    token = get_access_token(transfer.payment_id)
    details = fetch_transfer_details(transfer, token)
    
    log_content = read_log_file(transfer.payment_id)
    carpeta = obtener_ruta_schema_transferencia(transfer.payment_id)
    archivos_logs = {
        archivo: os.path.join(carpeta, archivo)
        for archivo in os.listdir(carpeta)
        if archivo.endswith(".log")
    }
    log_files_content = {}
    mensaje_error = None
    for nombre, ruta in archivos_logs.items():
        if os.path.exists(ruta):
            with open(ruta, 'r', encoding='utf-8') as f:
                contenido = f.read()
                log_files_content[nombre] = contenido
                if "=== Error ===" in contenido:
                    mensaje_error = contenido.split("=== Error ===")[-1].strip().split("===")[0].strip()
    archivos = {
        'pain001': os.path.join(carpeta, f"pain001_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"pain001_{transfer.payment_id}.xml")) else None,
        'aml': os.path.join(carpeta, f"aml_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"aml_{transfer.payment_id}.xml")) else None,
        'pain002': os.path.join(carpeta, f"pain002_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"pain002_{transfer.payment_id}.xml")) else None,
    }
    errores_detectados = []
    for contenido in log_files_content.values():
        if "Error" in contenido or "Traceback" in contenido or "no válido según el XSD" in contenido:
            errores_detectados.append(contenido)
    
    return render(request, "api/GPT4/transfer_detail.html", {
        "transfer": transfer,
        "details": details,
        'log_files_content': log_files_content,
        'log_content': log_content,
        'archivos': archivos,
        'errores_detectados': errores_detectados,
        'mensaje_error': mensaje_error
    })

def transfer_detail(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    log_content = read_log_file(transfer.payment_id)
    
    # Obtener logs de la base de datos
    logs_db = LogTransferencia.objects.filter(registro=transfer.payment_id).order_by('-created_at')

    logs_por_tipo = {
        'transferencia': logs_db.filter(tipo_log='TRANSFER'),
        'autenticacion': logs_db.filter(tipo_log='AUTH'),
        'errores': logs_db.filter(tipo_log='ERROR'),
        'xml': logs_db.filter(tipo_log='XML'),
        'aml': logs_db.filter(tipo_log='AML'),
        'sca': logs_db.filter(tipo_log='SCA'),
        'otp': logs_db.filter(tipo_log='OTP'),
        'oauth': logs_db.filter(tipo_log='OAUTH'),
    }
    
    # Detectar si hay errores
    errores_detectados = logs_db.filter(tipo_log='ERROR')
    mensaje_error = errores_detectados.first().contenido if errores_detectados.exists() else None
    
    
    carpeta = obtener_ruta_schema_transferencia(transfer.payment_id)
    archivos_logs = {
        archivo: os.path.join(carpeta, archivo)
        for archivo in os.listdir(carpeta)
        if archivo.endswith(".log")
    }
    log_files_content = {}
    mensaje_error = None
    for nombre, ruta in archivos_logs.items():
        if os.path.exists(ruta):
            with open(ruta, 'r', encoding='utf-8') as f:
                contenido = f.read()
                log_files_content[nombre] = contenido
                if "=== Error ===" in contenido:
                    mensaje_error = contenido.split("=== Error ===")[-1].strip().split("===")[0].strip()
    archivos = {
        'pain001': os.path.join(carpeta, f"pain001_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"pain001_{transfer.payment_id}.xml")) else None,
        'aml': os.path.join(carpeta, f"aml_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"aml_{transfer.payment_id}.xml")) else None,
        'pain002': os.path.join(carpeta, f"pain002_{transfer.payment_id}.xml") if os.path.exists(os.path.join(carpeta, f"pain002_{transfer.payment_id}.xml")) else None,
    }
    errores_detectados = []
    for contenido in log_files_content.values():
        if "Error" in contenido or "Traceback" in contenido or "no válido según el XSD" in contenido:
            errores_detectados.append(contenido)
    return render(request, 'api/GPT4/transfer_detail.html', {
        'transfer': transfer,
        'log_files_content': log_files_content,
        'logs_por_tipo': logs_por_tipo,
        'log_content': log_content,
        'archivos': archivos,
        'errores_detectados': errores_detectados,
        'mensaje_error': mensaje_error
    })


def send_transfer_view(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    form = SendTransferForm(request.POST or None, instance=transfer)
    token = None

    if request.session.get('oauth_active', False):
        token = request.session.get('access_token')
        expires = request.session.get('token_expires', 0)
        
        if not token or time.time() > expires - 60:
            rt = request.session.get('refresh_token')
            
            if rt:
                try:
                    token, rt_new, exp = refresh_access_token(rt)
                    request.session['access_token'] = token
                    request.session['refresh_token'] = rt_new or rt
                    request.session['token_expires'] = time.time() + exp
                except Exception as e:
                    token, exp = get_client_credentials_token()
                    request.session['access_token'] = token
                    request.session['token_expires'] = time.time() + exp
                    
            else:
                token, exp = get_client_credentials_token()
                request.session['access_token'] = token
                request.session['token_expires'] = time.time() + exp

    if request.method == "POST":
        try:
            if not form.is_valid():
                registrar_log(transfer.payment_id,tipo_log='ERROR',error="Formulario inválido",extra_info="Errores de validación en vista")
                messages.error(request, "Formulario inválido. Revisa los campos.")
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            
            manual_token = form.cleaned_data['manual_token']
            final_token = manual_token or token
            
            if not final_token:
                mensaje = "Para obtener el token, primero activa OAuth2 en la barra de navegación."
                registrar_log(transfer.payment_id, tipo_log='AUTH', error=mensaje, extra_info="Token ausente")
                messages.error(request, mensaje)
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            
            obtain_otp = form.cleaned_data['obtain_otp']
            manual_otp = form.cleaned_data['manual_otp']
            
            try:
                if obtain_otp:
                    method = form.cleaned_data.get('otp_method')
                    
                    if method == 'MTAN':
                        challenge_id = crear_challenge_mtan(transfer, final_token, transfer.payment_id)
                        transfer.auth_id = challenge_id
                        transfer.save()
                        return redirect('transfer_update_scaGPT4', payment_id=transfer.payment_id)
                    
                    elif method == 'PHOTOTAN':
                        challenge_id, img64 = crear_challenge_phototan(transfer, final_token, transfer.payment_id)
                        request.session['photo_tan_img'] = img64
                        transfer.auth_id = challenge_id
                        transfer.save()
                        return redirect('transfer_update_scaGPT4', payment_id=transfer.payment_id)
                    
                    else:
                        otp = resolver_challenge_pushtan(crear_challenge_pushtan(transfer, final_token, transfer.payment_id),final_token,transfer.payment_id)
                        
                elif manual_otp:
                    otp = manual_otp
                    
                else:
                    mensaje = "Debes seleccionar 'Obtener OTP automáticamente' o introducirlo manualmente."
                    registrar_log(transfer.payment_id, tipo_log='OTP', error=mensaje, extra_info="Falta OTP")
                    messages.error(request, mensaje)
                    return redirect('transfer_detailGPT4', payment_id=payment_id)
                
            except Exception as e:
                registrar_log(transfer.payment_id,tipo_log='OTP',error=str(e),extra_info="Error generando u obteniendo OTP")
                messages.error(request, str(e))
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            
            try:
                send_transfer(transfer, final_token, otp)
                messages.success(request, "Transferencia enviada correctamente.")
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            
            except Exception as e:
                registrar_log(transfer.payment_id,tipo_log='TRANSFER',error=str(e),extra_info="Error enviando transferencia SEPA")
                messages.error(request, str(e))
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            
        except Exception as e:
            registrar_log(transfer.payment_id,tipo_log='ERROR',error=str(e),extra_info="Excepción inesperada en vista send_transfer_view")
            messages.error(request, f"Error inesperado: {str(e)}")
            return redirect('transfer_detailGPT4', payment_id=payment_id)
        
    return render(request,"api/GPT4/send_transfer.html",{"form": form, "transfer": transfer})
        
            
            
def transfer_update_sca(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    form = ScaForm(request.POST or None)
    if request.method == 'POST':
        if form.is_valid():
            action = form.cleaned_data['action']
            otp = form.cleaned_data['otp']
            try:
                token = get_access_token(transfer.payment_id)
                from api.gpt4.utils import update_sca_request
                update_sca_request(transfer, action, otp, token)
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            except Exception as e:
                registrar_log(transfer.payment_id, {}, "", error=str(e), tipo_log='SCA', extra_info="Error procesando SCA en vista")
                mensaje_error = str(e)
                return _render_transfer_detail(request, transfer, mensaje_error)
        else:
            registrar_log(transfer.payment_id, {}, "", error="Formulario SCA inválido", tipo_log='SCA', extra_info="Errores validación SCA")
            mensaje_error = "Por favor corrige los errores en la autorización."
            return _render_transfer_detail(request, transfer, mensaje_error)
    return render(request, 'api/GPT4/transfer_sca.html', {'form': form, 'transfer': transfer})

def _render_transfer_detail(request, transfer, mensaje_error=None, details=None):
    if mensaje_error:
        registrar_log(
            transfer.payment_id,
            tipo_log='TRANSFER',
            error=mensaje_error,
            extra_info="Renderizando vista de detalle tras error"
        )

    log_content = read_log_file(transfer.payment_id)
    carpeta = obtener_ruta_schema_transferencia(transfer.payment_id)
    archivos = {
        nombre_base: os.path.join(carpeta, f"{nombre_base}_{transfer.payment_id}.xml")
        if os.path.exists(os.path.join(carpeta, f"{nombre_base}_{transfer.payment_id}.xml"))
        else None
        for nombre_base in ("pain001", "aml", "pain002")
    }

    log_files_content = {}
    errores_detectados = []
    try:
        for fichero in os.listdir(carpeta):
            if fichero.lower().endswith(".log"):
                ruta = os.path.join(carpeta, fichero)
                try:
                    with open(ruta, 'r', encoding='utf-8') as f:
                        contenido = f.read()
                except (IOError, OSError) as e:
                    contenido = f"Error al leer el log {fichero}: {e}"
                    errores_detectados.append(contenido)
                log_files_content[fichero] = contenido
                if any(p in contenido for p in ("Error", "Traceback", "no válido según el XSD")):
                    errores_detectados.append(contenido)
    except (IOError, OSError):
        mensaje_error = mensaje_error or "No se pudo acceder a los logs de la transferencia."

    contexto = {
        'transfer': transfer,
        'log_content': log_content,
        'archivos': archivos,
        'log_files_content': log_files_content,
        'errores_detectados': errores_detectados,
        'mensaje_error': mensaje_error,
        'details': details
    }
    return render(request, "api/GPT4/transfer_detail.html", contexto)


def edit_transfer(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    if request.method == "POST":
        form = TransferForm(request.POST, instance=transfer)
        if form.is_valid():
            form.save()
            messages.success(request, "Transferencia actualizada correctamente.")
            return redirect('transfer_detailGPT4', payment_id=payment_id)
        else:
            messages.error(request, "Por favor corrige los errores en el formulario.")
    else:
        form = TransferForm(instance=transfer)
    return render(request, 'api/GPT4/edit_transfer.html', {
        'form': form,
        'transfer': transfer
    })


# ==== PDF ====
def descargar_pdf(request, payment_id):
    transferencia = get_object_or_404(Transfer, payment_id=payment_id)
    generar_pdf_transferencia(transferencia)
    carpeta = obtener_ruta_schema_transferencia(payment_id)
    pdf_file = next(
        (os.path.join(carpeta, f) for f in os.listdir(carpeta) if f.endswith(".pdf") and payment_id in f),
        None
    )
    if not pdf_file or not os.path.exists(pdf_file):
        messages.error(request, "El archivo PDF no se encuentra disponible.")
        return redirect('transfer_detailGPT4', payment_id=transferencia.payment_id)
    return FileResponse(open(pdf_file, 'rb'), content_type='application/pdf', as_attachment=True, filename=os.path.basename(pdf_file))


# ==== OAUTH2 ====
def oauth2_authorize(request):
    try:
        if not request.session.get('oauth_active', False):
            registrar_log_oauth("inicio_autorizacion", "fallo", {"razon": "oauth_inactivo"}, request=request)
            registrar_log("OAUTH-AUTHORIZING", tipo_log="OAUTH", error="OAuth inactivo", extra_info="Intento de autorización sin flag activo")
            messages.error(request, "El flujo OAuth2 no está activado.")
            return redirect('dashboard')

        verifier, challenge = generate_pkce_pair()
        state = uuid.uuid4().hex

        request.session.update({
            'pkce_verifier': verifier,
            'oauth_state': state,
            'oauth_in_progress': True,
            'oauth_start_time': time.time()
        })

        auth_url = build_auth_url(state, challenge)

        registrar_log_oauth("inicio_autorizacion", "exito", {
            "state": state,
            "auth_url": auth_url,
            "code_challenge": challenge
        }, request=request)

        registrar_log("OAUTH-AUTHORIZING", tipo_log="OAUTH", request_body={
            "verifier": verifier,
            "challenge": challenge,
            "state": state
        }, extra_info="Inicio de flujo de autorización")

        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            return JsonResponse({'auth_url': auth_url})
        return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': auth_url})

    except Exception as e:
        registrar_log_oauth("inicio_autorizacion", "error", None, str(e), request=request)
        registrar_log("OAUTH-AUTHORIZING", tipo_log="OAUTH", error=str(e), extra_info="Excepción en oauth2_authorize")
        messages.error(request, "Error al iniciar autorización OAuth2")

    return render(request, 'api/GPT4/oauth2_callback.html', {'auth_url': None})


def oauth2_callback(request):
    try:
        if not request.session.get('oauth_in_progress', False):
            registrar_log_oauth("callback", "fallo", {"razon": "flujo_no_iniciado"}, request=request)
            registrar_log("OAUTH-CALLBACK", tipo_log="OAUTH", error="Flujo no iniciado", extra_info="oauth_in_progress no presente")
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
            registrar_log("OAUTH-CALLBACK", tipo_log="OAUTH", error=error, extra_info=error_desc)
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
            registrar_log("OAUTH-CALLBACK", tipo_log="OAUTH", error="State mismatch", extra_info=f"state={state}, esperado={session_state}")
            messages.error(request, "Error de seguridad: State mismatch")
            return render(request, 'api/GPT4/oauth2_callback.html')

        code = request.GET.get('code')
        verifier = request.session.pop('pkce_verifier', None)

        registrar_log_oauth("callback", "procesando", {"code": code, "state": state}, request=request)

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

        registrar_log("OAUTH-CALLBACK", tipo_log="OAUTH", request_body={
            "code": code,
            "verifier": verifier,
            "access_token": "***REDACTED***",
            "refresh_token": "***REDACTED***",
            "expires": expires
        }, extra_info="Token OAuth2 recibido correctamente")

        messages.success(request, "Autorización completada exitosamente!")
        return render(request, 'api/GPT4/oauth2_callback.html')

    except Exception as e:
        registrar_log_oauth("callback", "error", None, str(e), request=request)
        registrar_log("OAUTH-CALLBACK", tipo_log="OAUTH", error=str(e), extra_info="Excepción durante callback")
        request.session['oauth_success'] = False
        messages.error(request, f"Error en el proceso de autorización: {str(e)}")

    return render(request, 'api/GPT4/oauth2_callback.html')


def get_oauth_logs(request):
    from api.gpt4.models import LogTransferencia

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


def send_transfer_view4(request, payment_id):
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    form = SendTransferForm(request.POST or None)
    
    # Obtener o renovar token desde sesión
    token = request.session.get('access_token')
    expires = request.session.get('token_expires', 0)
    if not token or time.time() > expires - 60:
        rt = request.session.get('refresh_token')
        if rt:
            try:
                token, rt_new, exp = refresh_access_token(rt)
                request.session['access_token'] = token
                request.session['refresh_token'] = rt_new or rt
                request.session['token_expires'] = time.time() + exp
            except Exception:
                token, exp = get_client_credentials_token()
                request.session['access_token'] = token
                request.session['token_expires'] = time.time() + exp
        else:
            token, exp = get_client_credentials_token()
            request.session['access_token'] = token
            request.session['token_expires'] = time.time() + exp

    if request.method == "POST":
        if form.is_valid():
            manual_token = form.cleaned_data['manual_token']
            obtain_otp = form.cleaned_data['obtain_otp']
            manual_otp = form.cleaned_data['manual_otp']

            # Decidir token final
            final_token = manual_token or token

            # Obtener o usar OTP
            try:                   
                method = form.cleaned_data.get('otp_method')
                if obtain_otp:
                    if method == 'MTAN':
                        challenge_id = crear_challenge_mtan(transfer, token, transfer.payment_id)
                        transfer.auth_id = challenge_id
                        transfer.save()
                        return redirect('transfer_update_scaGPT4', payment_id=transfer.payment_id)
                    elif method == 'PHOTOTAN':
                        challenge_id, img64 = crear_challenge_phototan(transfer, token, transfer.payment_id)
                        request.session['photo_tan_img'] = img64
                        transfer.auth_id = challenge_id
                        transfer.save()
                        return redirect('transfer_update_scaGPT4', payment_id=transfer.payment_id)
                    else:  # PUSHTAN
                        otp = resolver_challenge_pushtan(crear_challenge_pushtan(transfer, token, transfer.payment_id), token, transfer.payment_id)
                else:
                    otp = manual_otp
                    
            except Exception as e:
                registrar_log(
                    transfer.payment_id,
                    {},
                    "",
                    error=str(e),
                    tipo_log='OTP',
                    extra_info="Error generando OTP automático en vista"
                )
                return _render_transfer_detail(request, transfer, mensaje_error=str(e))

            # Enviar transferencia
            try:
                send_transfer(transfer, final_token, otp)
                return redirect('transfer_detailGPT4', payment_id=payment_id)
            except Exception as e:
                registrar_log(
                    transfer.payment_id,
                    {},
                    "",
                    error=str(e),
                    tipo_log='TRANSFER',
                    extra_info="Error enviando transferencia en vista"
                )
                return _render_transfer_detail(request, transfer, mensaje_error=str(e))
        else:
            registrar_log(
                transfer.payment_id,
                {},
                "",
                error="Formulario inválido",
                tipo_log='TRANSFER',
                extra_info="Errores de validación en vista"
            )
            return _render_transfer_detail(
                request,
                transfer,
                mensaje_error="Debes seleccionar obtener OTP o proporcionar uno manualmente."
            )

    return render(
        request,
        "api/GPT4/send_transfer.html",
        {"form": form, "transfer": transfer}
    )

@require_POST
def toggle_oauth(request):
    request.session['oauth_active'] = 'oauth_active' in request.POST
    return redirect(request.META.get('HTTP_REFERER', 'dashboard'))


from api.gpt4.models import LogTransferencia

def list_logs(request):
    registro = request.GET.get("registro", "").strip()
    tipo_log = request.GET.get("tipo_log", "").strip()

    logs = LogTransferencia.objects.all()

    if registro:
        logs = logs.filter(registro__icontains=registro)
    if tipo_log:
        logs = logs.filter(tipo_log__iexact=tipo_log)

    logs = logs.order_by('-created_at')[:500]
    choices = LogTransferencia._meta.get_field('tipo_log').choices

    return render(request, 'api/GPT4/list_logs.html', {
        "logs": logs,
        "registro": registro,
        "tipo_log": tipo_log,
        "choices": choices
    })