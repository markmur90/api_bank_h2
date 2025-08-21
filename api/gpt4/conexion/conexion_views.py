import time
import socket
import json
from functools import lru_cache
from django.shortcuts import render, redirect, get_object_or_404
from django.http import JsonResponse
from django.contrib import messages
from django.views.decorators.http import require_http_methods, require_GET, require_POST

import netifaces
from api.gpt4.models import Transfer
from api.gpt4.forms import SendTransferForm
from api.gpt4.utils import registrar_log
from api.gpt4.conexion.conexion_banco import (
    get_settings,
    obtener_token,
    solicitar_otp,
    enviar_transferencia,
    consultar_estado,
    make_request,
)
from api.gpt4.conexion.decorators import requiere_conexion_banco
from api.configuraciones_api.helpers import get_conf



@require_http_methods(["GET", "POST"])
def send_transfer_bank_view(request, payment_id):
    """
    Vista mejorada para envío de transferencias con OTP automático PUSHTAN
    y certificados SSL de Deutsche Bank.
    """
    # 1) Cargar la transferencia existente
    transfer = get_object_or_404(Transfer, payment_id=payment_id)
    
    # 2) Formulario vinculado a la instancia
    form = SendTransferForm(request.POST or None, instance=transfer, context_mode='automatic')

    if request.method == "GET":
        try:
            # 3) Verificar disponibilidad de certificados SSL
            from api.gpt4.services.transfer_services import (
                verificar_certificados_disponibles, 
                DeutscheBankClient
            )
            
            certificados_disponibles, mensaje = verificar_certificados_disponibles()
            
            if certificados_disponibles:
                # 4) Usar cliente con certificados SSL
                client = DeutscheBankClient()
                
                # 5) Obtener credenciales del banco
                username = get_conf("BANK_USER")
                password = get_conf("BANK_PASS")
                
                if not username or not password:
                    messages.warning(request, "Credenciales bancarias no configuradas")
                    return redirect("transfer_detailGPT4", payment_id=payment_id)
                
                # 6) Obtener token con certificados SSL
                token, expires = client.obtener_token(username, password)
                
                # 7) Guardar en sesión
                request.session["bank_token"] = token
                request.session["bank_token_expires"] = expires
                request.session["use_ssl_certificates"] = True
                request.session["current_payment_id"] = payment_id
                
                # 8) Para PUSHTAN no necesitamos generar OTP manualmente
                request.session["otp_method"] = "PUSHTAN"
                
                registrar_log(
                    payment_id, 
                    tipo_log="AUTH",
                    extra_info="Token obtenido con certificados SSL. Usando PUSHTAN automático"
                )
                
                messages.success(
                    request, 
                    "✅ Autenticación exitosa con Deutsche Bank. "
                    "La transferencia se autorizará automáticamente con PUSHTAN."
                )
                
            else:
                # Fallback: método original sin certificados
                messages.warning(request, f"⚠️ {mensaje}. Usando método alternativo.")
                
                # Obtener token sin certificados
                token = obtener_token()
                request.session["bank_token"] = token
                request.session["use_ssl_certificates"] = False
                request.session["current_payment_id"] = payment_id
                request.session["otp_method"] = "MANUAL"
                
                messages.info(request, "Se requiere código OTP manual")
                
        except Exception as e:
            registrar_log(
                payment_id, 
                tipo_log="ERROR",
                error=str(e), 
                extra_info="Error en autenticación inicial"
            )
            messages.error(request, f"Error al iniciar la autenticación: {e}")
            return redirect("transfer_detailGPT4", payment_id=payment_id)

    elif request.method == "POST":
        # 9) Procesar envío de transferencia
        token = request.session.get("bank_token")
        use_ssl = request.session.get("use_ssl_certificates", False)
        otp_method = request.session.get("otp_method", "MANUAL")
        
        if not token:
            messages.error(request, "La sesión de autenticación expiró. Reinicia el proceso.")
            return redirect("transfer_detailGPT4", payment_id=payment_id)

        try:
            if use_ssl and otp_method == "PUSHTAN":
                # 10) ENVÍO CON CERTIFICADOS SSL Y PUSHTAN AUTOMÁTICO
                from api.gpt4.services.transfer_services import enviar_transferencia_con_pushtan
                
                registrar_log(
                    payment_id, 
                    tipo_log='TRANSFER', 
                    extra_info="Iniciando transferencia con certificados SSL y PUSHTAN automático"
                )
                
                # No necesitamos OTP manual, usar PUSHTAN
                # IP del PSU (cliente) si está disponible
                psu_ip = request.META.get('HTTP_X_FORWARDED_FOR')
                if psu_ip:
                    psu_ip = psu_ip.split(',')[0].strip()
                else:
                    psu_ip = request.META.get('REMOTE_ADDR')

                success, result = enviar_transferencia_con_pushtan(
                    payment_id=payment_id,
                    token=token,
                    psu_ip_address=psu_ip,
                )
                
                if success:
                    # 11) Actualizar estado de la transferencia
                    estado = result.get("transactionStatus", result.get("status"))
                    if estado:
                        transfer.status = estado
                        transfer.save()
                        
                        if estado in ["ACCP", "ACTC", "ACSC"]:
                            messages.success(
                                request, 
                                f"✅ Transferencia procesada exitosamente. Estado: {estado}"
                            )
                        elif estado == "PDNG":
                            messages.info(
                                request, 
                                f"⏳ Transferencia en proceso. Estado: {estado}"
                            )
                        else:
                            messages.warning(
                                request, 
                                f"⚠️ Transferencia enviada. Estado: {estado}"
                            )
                    
                    registrar_log(
                        payment_id, 
                        tipo_log="TRANSFER",
                        extra_info=f"Transferencia completada con PUSHTAN. Estado: {estado}"
                    )
                    
                    # 12) Limpiar sesión
                    for key in ["bank_token", "bank_token_expires", "use_ssl_certificates", 
                               "current_payment_id", "otp_method"]:
                        request.session.pop(key, None)
                    
                    return redirect("transfer_detailGPT4", payment_id=payment_id)
                    
                else:
                    # Error en transferencia con certificados
                    registrar_log(
                        payment_id, 
                        tipo_log='ERROR', 
                        error=result, 
                        extra_info="Error en transferencia con PUSHTAN"
                    )
                    messages.error(request, f"Error en transferencia: {result}")
                    
            else:
                # 13) FALLBACK: Método original con OTP manual
                otp_manual = request.POST.get('manual_otp') or form.cleaned_data.get('manual_otp')
                
                if not otp_manual:
                    messages.error(request, "Se requiere código OTP")
                    return render(request, "api/GPT4/send_transfer_bank.html", {
                        "transfer": transfer,
                        "form": form,
                        "require_manual_otp": True
                    })
                
                # Enviar con OTP manual
                resultado = enviar_transferencia(token, payment_id, otp_manual)
                
                estado = resultado.get("status")
                if estado:
                    transfer.status = estado
                    transfer.save()
                    messages.success(request, f"Transferencia procesada. Estado: {estado}")
                
                # Limpiar sesión
                for key in ["bank_token", "current_payment_id", "otp_method"]:
                    request.session.pop(key, None)
                
                return redirect("transfer_detailGPT4", payment_id=payment_id)
                
        except Exception as e:
            registrar_log(
                payment_id, 
                tipo_log="ERROR",
                error=str(e), 
                extra_info="Error al procesar transferencia"
            )
            messages.error(request, f"Error al procesar la transferencia: {e}")
            return redirect("transfer_detailGPT4", payment_id=payment_id)

    # 14) Renderizar formulario
    context = {
        "transfer": transfer,
        "form": form,
        "use_pushtan": request.session.get("otp_method") == "PUSHTAN",
        "use_ssl": request.session.get("use_ssl_certificates", False),
    }
    
    return render(request, "api/GPT4/send_transfer_bank.html", context)


@require_GET
@requiere_conexion_banco
def prueba_conexion_banco(request):
    """
    Prueba la conexión bancaria real o fake.
    """
    try:
        send_path = get_conf("SEND_PATH")
        resp = make_request("GET", send_path)
        data = resp.json()
        return JsonResponse({"estado": "ok", "respuesta": data})
    except Exception as e:
        return JsonResponse({"estado": "fallo", "detalle": str(e)}, status=502)

@require_POST
@requiere_conexion_banco
def toggle_conexion_banco(request):
    """
    Alterna el uso de conexión bancaria real vs mock en sesión.
    """
    estado = request.session.get("usar_conexion_banco", False)
    request.session["usar_conexion_banco"] = not estado
    messages.success(
        request,
        f"Conexión bancaria {'activada' if not estado else 'desactivada'}."
    )
    return redirect(request.META.get("HTTP_REFERER", "/"))



from django.views.decorators.http import require_GET
from django.shortcuts import get_object_or_404, redirect, render
import socket

try:
    import netifaces
    usar_netifaces = True
except ImportError:
    usar_netifaces = False
    
@require_GET
def diagnostico_banco(request):
    settings = get_settings()
    dominio_banco = settings["DOMINIO_BANCO"]
    red_segura_prefix = settings["RED_SEGURA_PREFIX"]
    puerto_mock = settings["MOCK_PORT"]

    # === IP Local y Red Segura ===
    ip_local = "❌ No detectada"
    en_red_segura = False
    try:
        if usar_netifaces:
            interfaces = netifaces.interfaces()
            for iface in interfaces:
                addrs = netifaces.ifaddresses(iface)
                if netifaces.AF_INET in addrs:
                    for link in addrs[netifaces.AF_INET]:
                        ip = link['addr']
                        if ip.startswith(red_segura_prefix):
                            ip_local = ip
                            en_red_segura = True
                            break
        else:
            hostname = socket.gethostname()
            ip = socket.gethostbyname(hostname)
            ip_local = ip
            en_red_segura = ip.startswith(red_segura_prefix)
    except Exception as e:
        ip_local = f"❌ Error detectando IP: {e}"

    # === DNS del dominio ===
    try:
        ip_remoto = socket.gethostbyname(dominio_banco)
        dns_status = f"✅ {dominio_banco} → {ip_remoto}"
    except Exception as e:
        ip_remoto = None
        dns_status = f"❌ Error resolviendo {dominio_banco}: {e}"

    # === Acceso al puerto del mock ===
    try:
        if ip_remoto:
            with socket.create_connection((ip_remoto, puerto_mock), timeout=5):
                conexion_status = f"✅ Puerto {puerto_mock} accesible en {ip_remoto}"
        else:
            conexion_status = "⛔ No se resolvió IP, no se prueba puerto"
    except Exception as e:
        conexion_status = f"❌ Puerto {puerto_mock} no accesible: {e}"

    return render(request, "api/extras/diagnostico_banco.html", {
        "ip_local": ip_local,
        "dns_status": dns_status,
        "conexion_status": conexion_status,
        "en_red_segura": en_red_segura,
    })