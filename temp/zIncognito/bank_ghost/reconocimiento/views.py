# reconocimiento/views.py

import os
import json
import subprocess
import uuid
import traceback
import time as systime

from datetime import datetime

from django.conf import settings
from django.core.files import File
from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse, JsonResponse
from django.shortcuts import render, redirect, get_object_or_404
from django.template.loader import render_to_string
from django.urls import reverse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST

import weasyprint

from .models import IntentoReconocimiento, PerfilUsuario, UrlMonitoreada
from .forms import EjecucionReconForm, UrlSeleccionForm


def registrar_intento_desde_log(log_path, captura_path, tiempo_navegacion=60, url_override=None):
    """
    Crea un IntentoReconocimiento a partir de un log y una captura.
    - Espera hasta 10s a que el archivo log exista.
    - Usa url_override si no extrae la URL del log.
    """
    # Esperar a que el log exista
    for _ in range(10):
        if os.path.exists(log_path):
            break
        systime.sleep(1)
    if not os.path.exists(log_path):
        print(f"❌ Log no encontrado: {log_path}")
        return None

    # Leer contenido
    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(prefix):
        for linea in contenido.splitlines():
            if linea.strip().startswith(prefix):
                return linea.split(":", 1)[1].strip()
        return ""

    user_agent = extraer_linea("User-Agent") or "Desconocido"
    url = extraer_linea("URL") or url_override or "https://desconocida.com"
    ids = extraer_linea("Identificadores buscados") or ""
    reconocio = "SÍ" in extraer_linea("Reconocido")

    # Crear registro en base de datos
    intento = IntentoReconocimiento.objects.create(
        url=url,
        identificadores=ids,
        user_agent=user_agent,
        reconocio=reconocio,
        tiempo_navegacion=tiempo_navegacion
    )

    # Guardar archivos si existen
    if os.path.exists(log_path):
        with open(log_path, 'rb') as f:
            nombre = os.path.basename(log_path)
            intento.log.save(nombre, File(f), save=False)
    if os.path.exists(captura_path):
        with open(captura_path, 'rb') as f:
            nombre = os.path.basename(captura_path)
            intento.captura.save(nombre, File(f), save=False)

    intento.save()
    return intento


@login_required
def dashboard(request):
    perfil, _ = PerfilUsuario.objects.get_or_create(user=request.user)

    limite      = int(request.GET.get("limite", 10))
    total       = IntentoReconocimiento.objects.count()
    reconocidos = IntentoReconocimiento.objects.filter(reconocio=True).count()
    recientes   = IntentoReconocimiento.objects.order_by('-fecha')[:limite]

    desde_ejecutar = (
        IntentoReconocimiento.objects.filter(log__contains="intento_") |
        IntentoReconocimiento.objects.filter(log__contains="manual_")
    ).order_by("-fecha")[:10]

    desde_seleccionar = IntentoReconocimiento.objects.filter(log__contains="seleccion_") \
        .order_by("-fecha")[:10]

    ultimo_intento = IntentoReconocimiento.objects.order_by('-fecha')[:10]

    contexto = {
        'nav_type':              'act',
        'total':                 total,
        'reconocidos':           reconocidos,
        'recientes':             recientes,
        'limite':                limite,
        'desde_ejecutar':        desde_ejecutar,
        'desde_seleccionar':     desde_seleccionar,
        'ultimo_intento':        ultimo_intento,
        'tema_usuario':          perfil.tema,
        'modo_verificacion_tor': request.user.verificacion_tor,
    }

    return render(request, 'dashboard.html', contexto)


@require_POST
def set_nav(request):
    nav = request.POST.get('nav_type')
    if nav in ('default', 'alt', 'act'):
        request.session['nav_type'] = nav
        return JsonResponse({'status': 'ok', 'nav_type': nav})
    return JsonResponse({'status': 'error'}, status=400)


@login_required
def lista_intentos(request):
    intentos = IntentoReconocimiento.objects.order_by('-fecha')
    return render(request, 'lista.html', {'intentos': intentos})


@login_required
def detalle_intento(request, pk):
    intento = get_object_or_404(IntentoReconocimiento, pk=pk)
    return render(request, 'detalle.html', {'intento': intento})


@login_required
@staff_member_required
def reinicio_seguro(request):
    if request.method == "POST":
        script_path = os.path.join(settings.BASE_DIR, "xx_run_todo_ghost.sh")
        if not os.path.exists(script_path):
            messages.error(request, "❌ El script de reinicio no existe.")
            return redirect("dashboard")
        try:
            # Ejecuta con sudo (gracias a sudoers sin password)
            subprocess.Popen(
                ["sudo", "bash", script_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            messages.success(request, "🔄 Reinicio seguro en curso.")
            return redirect(f"{reverse('dashboard')}?reinicio=ok")
        except Exception as e:
            messages.error(request, f"⚠️ Error al ejecutar el reinicio: {e}")
            return redirect("dashboard")
    return redirect("dashboard")


@login_required
def exportar_pdf(request):
    hoy = datetime.now().date()
    intentos = IntentoReconocimiento.objects.filter(fecha__date=hoy)
    html = render_to_string("reporte_pdf.html", {"intentos": intentos, "fecha": hoy})
    pdf = weasyprint.HTML(string=html).write_pdf()
    response = HttpResponse(pdf, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="reporte_{hoy}.pdf"'
    return response


@login_required
def ejecutar_reconocimientoC(request):
    if request.method == "POST":
        form = EjecucionReconForm(request.POST)
        if form.is_valid():
            modo = form.cleaned_data["modo"]
            urls = (
                form.cleaned_data["urls"]
                if modo == "lista"
                else UrlMonitoreada.objects.all()
                if modo == "todas"
                else [UrlMonitoreada.objects.get_or_create(url=form.cleaned_data["url_manual"])[0]]
            )
            ids = form.cleaned_data["identificadores"]
            repeticiones = form.cleaned_data["repeticiones"]
            delay = form.cleaned_data["delay"]
            tiempo_navegacion = form.cleaned_data["tiempo_navegacion"]

            for url_obj in urls:
                url_final = url_obj.url
                timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                intento_id = f"intento_{timestamp}_{uuid.uuid4().hex[:6]}"

                log_rel     = os.path.join("logs", f"log_{intento_id}.txt")
                captura_rel = os.path.join("capturas", f"captura_{intento_id}.png")
                log_abs     = os.path.join(settings.MEDIA_ROOT, log_rel)
                captura_abs = os.path.join(settings.MEDIA_ROOT, captura_rel)

                comando = [
                    "python3",
                    os.path.join(settings.BASE_DIR, "scripts", "ghost_recon_ultimate.py"),
                    url_final,
                    ids,
                    str(repeticiones),
                    str(delay),
                    intento_id,
                    f"--tiempo={tiempo_navegacion}"
                ]

                try:
                    subprocess.Popen(comando, cwd=os.path.dirname(comando[0]))
                    systime.sleep(3)
                    intento = registrar_intento_desde_log(log_abs, captura_abs, tiempo_navegacion, url_override=url_final)
                    if intento is None:
                        messages.warning(request, f"No se pudo registrar intento para {url_final}.")
                    else:
                        messages.success(request, f"Ejecución en segundo plano iniciada para: {url_final}")
                except Exception as e:
                    messages.error(request, f"Error al lanzar análisis para {url_final}: {e}")

            return redirect("dashboard")
    else:
        form = EjecucionReconForm()
    return render(request, "ejecutar_recon.html", {"form": form})


@login_required
def seleccionar_url(request):
    intento_mostrado = None
    if request.method == "POST":
        form = UrlSeleccionForm(request.POST)
        if form.is_valid():
            url = form.cleaned_data["url"]
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            intento_id = f"seleccion_{timestamp}"

            log_rel     = os.path.join("logs", f"log_{intento_id}.txt")
            captura_rel = os.path.join("capturas", f"captura_{intento_id}.png")
            log_abs     = os.path.join(settings.MEDIA_ROOT, log_rel)
            captura_abs = os.path.join(settings.MEDIA_ROOT, captura_rel)

            comando = [
                "python3",
                os.path.join(settings.BASE_DIR, "scripts", "ghost_recon_ultimate.py"),
                url,
                ",".join(["usuario","token","ip","correo"]),
                "3","10",intento_id,
                "--interactivo",
                "--tiempo=60"
            ]

            try:
                subprocess.run(comando, check=True)
                intento = registrar_intento_desde_log(log_abs, captura_abs, 60, url_override=url)
                if intento:
                    request.session["ultimo_intento_id"] = intento.id
                    messages.success(request, f"Ghost Recon ejecutado para {url}.")
                else:
                    messages.warning(request, f"No se pudo registrar intento para {url}.")
            except Exception as e:
                messages.error(request, f"Error ejecutando Ghost Recon: {e}")

            return redirect("seleccionar_url")
    else:
        form = UrlSeleccionForm()
        intento_id = request.session.get("ultimo_intento_id")
        if intento_id:
            intento_mostrado = IntentoReconocimiento.objects.filter(id=intento_id).first()

    return render(request, "seleccionar_url.html", {"form": form, "intento": intento_mostrado})


@login_required
def ultimos_intentos_json(request):
    intentos = IntentoReconocimiento.objects.order_by('-fecha')[:10]
    datos = [{
        "fecha": intento.fecha.strftime("%Y-%m-%d %H:%M:%S"),
        "reconocio": intento.reconocio,
        "captura": intento.captura.url if intento.captura else None,
        "tiempo": intento.tiempo_navegacion
    } for intento in intentos]
    return JsonResponse(datos, safe=False)


@csrf_exempt
@require_POST
def marcar_notificado(request):
    ids = json.loads(request.body.decode()).get("ids", [])
    actualizados = IntentoReconocimiento.objects.filter(id__in=ids, notificado=False).update(notificado=True)
    return JsonResponse({"actualizados": actualizados})


@staff_member_required
@require_POST
def reiniciar_identidad_tor(request):
    try:
        from stem import Signal
        from stem.control import Controller

        with Controller.from_port(port=9051) as controller:
            controller.authenticate(password=settings.TOR_PASS)
            controller.signal(Signal.NEWNYM)

        messages.success(request, "🧅 Nueva identidad Tor activada.")
    except Exception as e:
        messages.error(request, f"❌ Error al reiniciar Tor: {e}")
    return redirect("dashboard")


def verificar_tor(request):
    import requests
    try:
        r = requests.get(
            "https://check.torproject.org/",
            proxies={"http": "socks5h://127.0.0.1:9050", "https": "socks5h://127.0.0.1:9050"},
            timeout=10
        )
        ok = "Congratulations. This browser is configured to use Tor" in r.text
    except:
        ok = False
    return JsonResponse({"tor": ok})


def obtener_ip_publica(request):
    import requests
    try:
        r = requests.get("https://api.ipify.org?format=json", timeout=5)
        ip = r.json().get("ip", "Desconocida")
    except:
        ip = "Desconocida"
    return JsonResponse({"ip": ip})


@login_required
def cambiar_tema(request):
    if request.method == "POST":
        nuevo_tema = request.POST.get("tema")
        if nuevo_tema in ["claro", "oscuro"]:
            perfil = request.user.perfilusuario
            perfil.tema = nuevo_tema
            perfil.save()
            return JsonResponse({"estado": "ok", "tema": nuevo_tema})
    return JsonResponse({"estado": "error"}, status=400)


@login_required
def cambiar_modo_tor(request):
    if request.method == "POST":
        modo = request.POST.get("modo")
        if modo in ["backend", "navegador"]:
            request.user.verificacion_tor = modo
            request.user.save()
            return JsonResponse({"estado": "ok", "modo": modo})
    return JsonResponse({"estado": "error"}, status=400)
