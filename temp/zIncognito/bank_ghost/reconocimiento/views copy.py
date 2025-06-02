import os
import json
import subprocess
from datetime import datetime, time
import time as systime
import uuid
from django.core.files import File
import traceback

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.http import HttpResponse, JsonResponse
from django.urls import reverse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.template.loader import render_to_string
import weasyprint
from django.contrib.admin.views.decorators import staff_member_required
from django.contrib.auth.decorators import login_required
from django.shortcuts import render
from .models import IntentoReconocimiento, PerfilUsuario
from bank_ghost import settings
from .models import IntentoReconocimiento, UrlMonitoreada
from .forms import EjecucionReconForm, UrlSeleccionForm


# ==========================
# DASHBOARD + INTENTOS
# ==========================

@login_required
def dashboard(request):
    perfil, _ = PerfilUsuario.objects.get_or_create(user=request.user)

    limite       = int(request.GET.get("limite", 10))
    totales      = IntentoReconocimiento.objects.count()
    reconocidos  = IntentoReconocimiento.objects.filter(reconocio=True).count()
    recientes    = IntentoReconocimiento.objects.order_by('-fecha')[:limite]

    desde_ejecutar = (
        IntentoReconocimiento.objects
        .filter(log__contains="intento_")
        | IntentoReconocimiento.objects.filter(log__contains="manual_")
    ).order_by("-fecha")[:10]

    desde_seleccionar = (
        IntentoReconocimiento.objects
        .filter(log__contains="seleccion_")
        .order_by("-fecha")[:10]
    )

    ultimo_intento = IntentoReconocimiento.objects.order_by('-fecha')[:10]

    contexto = {
        'nav_type':              'act',
        'total':                 totales,
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



@login_required
def lista_intentos(request):
    intentos = IntentoReconocimiento.objects.order_by('-fecha')
    return render(request, "lista.html", {"intentos": intentos})


@login_required
def detalle_intento(request, pk):
    intento = get_object_or_404(IntentoReconocimiento, pk=pk)
    return render(request, "detalle.html", {"intento": intento})


@login_required
@staff_member_required
def reinicio_seguro(request):
    if request.method == "POST":
        script_path = os.path.join(settings.BASE_DIR, "scripts", "ghost", "xx_run_ghost.sh")

        if not os.path.exists(script_path):
            messages.error(request, "❌ El script de reinicio no existe.")
            return redirect("dashboard")

        try:
            subprocess.Popen(["bash", script_path])
            # Redirige a ejecutar con parámetro para mostrar toast
            return redirect(f"{reverse('dashboard')}?reinicio=ok")
        except Exception as e:
            messages.error(request, f"⚠️ Error al ejecutar el reinicio: {e}")
            return redirect("dashboard")

    return redirect("dashboard")


# ==========================
# EXPORTAR PDF
# ==========================

@login_required
def exportar_pdf(request):
    hoy = datetime.now().date()
    intentos = IntentoReconocimiento.objects.filter(fecha__date=hoy)
    html = render_to_string("reporte_pdf.html", {"intentos": intentos, "fecha": hoy})
    pdf = weasyprint.HTML(string=html).write_pdf()
    response = HttpResponse(pdf, content_type='application/pdf')
    response['Content-Disposition'] = f'inline; filename="reporte_{hoy}.pdf"'
    return response


# ==========================
# EJECUTAR RECONOCIMIENTO
# ==========================

@login_required
def ejecutar_reconocimientoA(request):
    if request.method == 'POST':
        form = EjecucionReconForm(request.POST)
        if form.is_valid():
            modo = form.cleaned_data['modo']
            ids = form.cleaned_data['identificadores']
            repeticiones = form.cleaned_data['repeticiones']
            delay = form.cleaned_data['delay']
            tiempo_navegacion = form.cleaned_data['tiempo_navegacion']

            if modo == 'lista':
                urls = form.cleaned_data['urls']
            elif modo == 'todas':
                urls = UrlMonitoreada.objects.all()
            elif modo == 'manual':
                url_manual = form.cleaned_data['url_manual']
                if not url_manual:
                    messages.error(request, "Debes ingresar una URL válida.")
                    return render(request, 'ejecutar_recon.html', {'form': form})
                url_obj, created = UrlMonitoreada.objects.get_or_create(url=url_manual)
                if created:
                    messages.success(request, f"La URL '{url_manual}' fue registrada en el sistema.")
                urls = [url_obj]
            else:
                messages.error(request, "Modo no válido.")
                return render(request, 'ejecutar_recon.html', {'form': form})

            ruta_script = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')

            if modo == 'manual':
                url_obj = urls[0]
                url_final = url_obj.url
                intento_id_base = f"manual_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                script_path = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')

                for r in range(1, repeticiones + 1):
                    intento_id = f"{intento_id_base}_r{r}"
                    log_nombre = f"log_{intento_id}.txt"
                    captura_nombre = f"captura_{intento_id}.png"

                    log_path = os.path.join('logs', log_nombre)
                    captura_path = os.path.join('capturas', captura_nombre)

                    cmd = [
                        'python3',
                        script_path,
                        url_final,
                        ids,
                        "1",  # solo una ejecución por vez
                        "0",  # sin delay dentro del script
                        intento_id,
                        '--interactivo',
                        f'--tiempo={tiempo_navegacion}'
                    ]

                    try:
                        subprocess.run(cmd, cwd=os.path.dirname(script_path), check=True)
                        registrar_intento_desde_log(
                            os.path.join(settings.BASE_DIR, 'bank_ghost', log_path),
                            os.path.join(settings.BASE_DIR, 'bank_ghost', captura_path),
                            tiempo_navegacion
                        )
                        if r < repeticiones:
                            systime.sleep(3)
                    except Exception as e:
                        messages.error(request, f"Error en repetición {r}: {e}")

                messages.success(request, f"Reconocimiento finalizado en {repeticiones} repeticiones para {url_final}.")
                return redirect('dashboard')

            else:
                for i, url_obj in enumerate(urls, start=1):
                    url_final = url_obj.url
                    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
                    intento_id = f"{i}_{timestamp}"

                    log_nombre = f"log_{intento_id}.txt"
                    captura_nombre = f"captura_{intento_id}.png"
                    log_path = os.path.join('logs', log_nombre)
                    captura_path = os.path.join('capturas', captura_nombre)

                    cmd = [
                        'python3',
                        ruta_script,
                        url_final,
                        ids,
                        str(repeticiones),
                        str(delay),
                        intento_id,
                        f'--tiempo={tiempo_navegacion}'
                    ]

                    subprocess.Popen(cmd, cwd=os.path.dirname(ruta_script))
                    systime.sleep(3)
                    registrar_intento_desde_log(
                        os.path.join(settings.BASE_DIR, 'bank_ghost', log_path),
                        os.path.join(settings.BASE_DIR, 'bank_ghost', captura_path),
                        tiempo_navegacion
                    )
                    messages.success(request, f'Ejecución en segundo plano iniciada para: {url_final}')

                return redirect('dashboard')
    else:
        form = EjecucionReconForm()

    return render(request, 'ejecutar_recon.html', {'form': form})

@login_required
def ejecutar_reconocimientoB(request):
    if request.method == 'POST':
        form = EjecucionReconForm(request.POST)
        if form.is_valid():
            modo = form.cleaned_data['modo']
            ids = form.cleaned_data['identificadores']
            repeticiones = form.cleaned_data['repeticiones']
            delay = form.cleaned_data['delay']
            tiempo_navegacion = form.cleaned_data['tiempo_navegacion']

            if modo == 'lista':
                urls = form.cleaned_data['urls']
            elif modo == 'todas':
                urls = UrlMonitoreada.objects.all()
            elif modo == 'manual':
                url_manual = form.cleaned_data['url_manual']
                if not url_manual:
                    messages.error(request, "Debes ingresar una URL válida.")
                    return render(request, 'ejecutar_recon.html', {'form': form})
                url_obj, created = UrlMonitoreada.objects.get_or_create(url=url_manual)
                if created:
                    messages.success(request, f"La URL '{url_manual}' fue registrada en el sistema.")
                urls = [url_obj]
            else:
                messages.error(request, "Modo no válido.")
                return render(request, 'ejecutar_recon.html', {'form': form})

            ruta_script = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')

            for url_obj in urls:
                url_final = url_obj.url
                intento_id_base = f"intento_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

                for r in range(1, repeticiones + 1):
                    intento_id = f"{intento_id_base}_r{r}"
                    log_nombre = f"log_{intento_id}.txt"
                    captura_nombre = f"captura_{intento_id}.png"
                    log_path = os.path.join('media/logs', log_nombre)
                    captura_path = os.path.join('media/capturas', captura_nombre)

                    cmd = [
                        'python3',
                        ruta_script,
                        url_final,
                        ids,
                        "1",  # solo una ejecución por repetición
                        "0",  # sin delay dentro del script
                        intento_id,
                        '--interactivo',
                        f'--tiempo={tiempo_navegacion}'
                    ]

                    try:
                        subprocess.run(cmd, cwd=os.path.dirname(ruta_script), check=True)
                        registrar_intento_desde_log(
                            os.path.join(settings.BASE_DIR, 'bank_ghost', log_path),
                            os.path.join(settings.BASE_DIR, 'bank_ghost', captura_path),
                            tiempo_navegacion
                        )
                        if r < repeticiones:
                            systime.sleep(delay)
                    except Exception as e:
                        messages.error(request, f"Error en '{url_final}' repetición {r}: {e}")

            messages.success(request, f"Reconocimiento completado en {repeticiones} repeticiones por URL.")
            return redirect('dashboard')
    else:
        form = EjecucionReconForm()

    return render(request, 'ejecutar_recon.html', {'form': form})

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
                intento_id = f"intento_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"
                log = f"media/logs/log_{intento_id}.txt"
                captura = f"media/capturas/captura_{intento_id}.png"

                comando = [
                    "python3",
                    os.path.join(settings.BASE_DIR, "bank_ghost", "ghost_recon_ultimate.py"),
                    url_obj.url,
                    ids,
                    str(repeticiones),
                    str(delay),
                    intento_id,
                    f"--tiempo={tiempo_navegacion}"
                ]

                try:
                    subprocess.Popen(comando, cwd=os.path.join(settings.BASE_DIR, "bank_ghost"))
                    messages.success(request, f"Ejecución en segundo plano para {url_obj.url}")
                except Exception as e:
                    messages.error(request, f"Error al lanzar análisis: {e}")

            return redirect("dashboard")
    else:
        form = EjecucionReconForm()
    return render(request, "ejecutar_recon.html", {"form": form})

@login_required
def ejecutar_reconocimientoD(request):
    if request.method == 'POST':
        form = EjecucionReconForm(request.POST)
        if form.is_valid():
            modo = form.cleaned_data['modo']
            ids = form.cleaned_data['identificadores']
            repeticiones = form.cleaned_data['repeticiones']
            delay = form.cleaned_data['delay']
            tiempo_navegacion = form.cleaned_data['tiempo_navegacion']

            if modo == 'lista':
                urls = form.cleaned_data['urls']
            elif modo == 'todas':
                urls = UrlMonitoreada.objects.all()
            elif modo == 'manual':
                url_manual = form.cleaned_data['url_manual']
                if not url_manual:
                    messages.error(request, "Debes ingresar una URL válida.")
                    return render(request, 'ejecutar_recon.html', {'form': form})
                url_obj, created = UrlMonitoreada.objects.get_or_create(url=url_manual)
                if created:
                    messages.success(request, f"La URL '{url_manual}' fue registrada en el sistema.")
                urls = [url_obj]
            else:
                messages.error(request, "Modo no válido.")
                return render(request, 'ejecutar_recon.html', {'form': form})

            ruta_script = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')

            for url_obj in urls:
                url_final = url_obj.url
                intento_id_base = f"intento_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

                for r in range(1, repeticiones + 1):
                    intento_id = f"{intento_id_base}_r{r}"
                    log_nombre = f"log_{intento_id}.txt"
                    captura_nombre = f"captura_{intento_id}.png"

                    log_path_rel = os.path.join('media', 'logs', log_nombre)
                    captura_path_rel = os.path.join('media', 'capturas', captura_nombre)
                    log_path_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', log_path_rel)
                    captura_path_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', captura_path_rel)

                    cmd = [
                        'python3',
                        ruta_script,
                        url_final,
                        ids,
                        "1",  # solo una repetición por ejecución
                        "0",  # sin delay interno
                        intento_id,
                        '--interactivo',
                        f'--tiempo={tiempo_navegacion}'
                    ]

                    try:
                        subprocess.run(cmd, cwd=os.path.dirname(ruta_script), check=True)
                        registrar_intento_desde_log(log_path_abs, captura_path_abs, tiempo_navegacion)
                        if r < repeticiones:
                            systime.sleep(delay)
                    except Exception as e:
                        messages.error(request, f"Error en '{url_final}' repetición {r}: {e}")

            messages.success(request, f"Reconocimiento completado en {repeticiones} repeticiones por URL.")
            return redirect('dashboard')
    else:
        form = EjecucionReconForm()

    return render(request, 'ejecutar_recon.html', {'form': form})

@login_required
def ejecutar_reconocimientoE(request):
    if request.method == 'POST':
        form = EjecucionReconForm(request.POST)
        if form.is_valid():
            modo = form.cleaned_data['modo']
            ids_raw = form.cleaned_data['identificadores']
            ids_list = [i.strip() for i in ids_raw.split(',') if i.strip()]
            if not ids_list:
                messages.error(request, "⚠️ Debes ingresar al menos un identificador válido (usuario, ip, etc).")
                return render(request, 'ejecutar_recon.html', {'form': form})
            ids = ",".join(ids_list)

            repeticiones = form.cleaned_data['repeticiones']
            delay = form.cleaned_data['delay']
            tiempo_navegacion = form.cleaned_data['tiempo_navegacion']

            if modo == 'lista':
                urls = form.cleaned_data['urls']
            elif modo == 'todas':
                urls = UrlMonitoreada.objects.all()
            elif modo == 'manual':
                url_manual = form.cleaned_data['url_manual']
                if not url_manual:
                    messages.error(request, "Debes ingresar una URL válida.")
                    return render(request, 'ejecutar_recon.html', {'form': form})
                url_obj, _ = UrlMonitoreada.objects.get_or_create(url=url_manual)
                urls = [url_obj]
            else:
                messages.error(request, "Modo no válido.")
                return render(request, 'ejecutar_recon.html', {'form': form})

            ruta_script = os.path.join(settings.BASE_DIR, 'bank_ghost', 'ghost_recon_ultimate.py')
            errores_path = os.path.join(settings.BASE_DIR, 'logs', 'errores_recon.txt')
            os.makedirs(os.path.dirname(errores_path), exist_ok=True)

            for url_obj in urls:
                url_final = url_obj.url
                intento_id_base = f"intento_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

                for r in range(1, repeticiones + 1):
                    intento_id = f"{intento_id_base}_r{r}"
                    log_rel = f"media/logs/log_{intento_id}.txt"
                    captura_rel = f"media/capturas/captura_{intento_id}.png"
                    log_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', log_rel)
                    captura_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', captura_rel)

                    cmd = [
                        'python3',
                        ruta_script,
                        url_final,
                        ids,
                        "1",
                        "0",
                        intento_id,
                        '--interactivo',
                        f'--tiempo={tiempo_navegacion}'
                    ]

                    try:
                        result = subprocess.run(cmd, cwd=os.path.dirname(ruta_script), check=True, capture_output=True, text=True)
                        intento = registrar_intento_desde_log(log_abs, captura_abs, tiempo_navegacion, url_override=url_final)
                        if intento:
                            print(f"✅ Intento registrado correctamente con ID: {intento.id}")
                        else:
                            print(f"⚠️ Fallo al registrar intento desde: {log_abs}")
                        if r < repeticiones:
                            systime.sleep(delay)

                    except subprocess.CalledProcessError as e:
                        error_msg = (
                            f"\n[!] Error en '{url_final}' repetición {r} - Código de salida: {e.returncode}\n"
                            f"Comando: {' '.join(cmd)}\n"
                            f"STDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}\n"
                        )
                        messages.error(request, f"Error en '{url_final}' repetición {r}. Verifica los logs.")
                        with open(errores_path, 'a', encoding='utf-8') as f:
                            f.write(error_msg)

                    except Exception as ex:
                        tb = traceback.format_exc()
                        messages.error(request, f"Excepción inesperada en '{url_final}' repetición {r}.")
                        with open(errores_path, 'a', encoding='utf-8') as f:
                            f.write(f"\n[!] Excepción en intento {intento_id}:\n{tb}\n")

            messages.success(request, f"Reconocimiento completado.")
            return redirect('dashboard')
    else:
        form = EjecucionReconForm()

    return render(request, 'ejecutar_recon.html', {'form': form})



# ==========================
# REGISTRAR INTENTO DESDE LOG
# ==========================

def registrar_intento_desde_logA(log_path, captura_path, tiempo_navegacion=60):
    if not os.path.exists(log_path):
        return

    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(valor):
        for linea in contenido.splitlines():
            if linea.startswith(valor):
                return linea.split(":", 1)[1].strip()
        return ""

    fecha_str = extraer_linea("Fecha")
    user_agent = extraer_linea("User-Agent")
    url = extraer_linea("URL")
    ids = extraer_linea("Identificadores buscados")
    reconocio = "SÍ" in extraer_linea("Reconocido")

    intento = IntentoReconocimiento.objects.create(
        url=url,
        identificadores=ids,
        user_agent=user_agent,
        reconocio=reconocio,
        log=f"media/logs/{os.path.basename(log_path)}",
        captura=f"media/capturas/{os.path.basename(captura_path)}",
        tiempo_navegacion=tiempo_navegacion
    )
    return intento

def registrar_intento_desde_logB(log_path, captura_path, tiempo_navegacion):
    # Esperar máximo 10 segundos a que el log aparezca
    intentos = 0
    while not os.path.exists(log_path) and intentos < 10:
        systime.sleep(3)
        intentos += 1

    if not os.path.exists(log_path):
        print(f"❌ Log no encontrado: {log_path}")
        return

    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(valor):
        for linea in contenido.splitlines():
            if linea.strip().startswith(valor):
                return linea.split(":", 1)[1].strip()
        return ""

    fecha_str = extraer_linea("Fecha")
    user_agent = extraer_linea("User-Agent")
    url = extraer_linea("URL")
    ids = extraer_linea("Identificadores buscados")
    reconocio = "SÍ" in extraer_linea("Reconocido")

    # Crear objeto primero sin archivo
    intento = IntentoReconocimiento.objects.create(
        url=url or "https://undefined.com",
        identificadores=ids or "No definido",
        user_agent=user_agent or "Desconocido",
        reconocio=reconocio,
        tiempo_navegacion=tiempo_navegacion
    )

    # Guardar log y captura luego, si existen
    log_absoluto = os.path.abspath(log_path)
    captura_absoluto = os.path.abspath(captura_path)

    if os.path.exists(log_absoluto):
        with open(log_absoluto, 'rb') as f:
            intento.log.save(os.path.basename(log_path), File(f), save=False)

    if os.path.exists(captura_absoluto):
        with open(captura_absoluto, 'rb') as f:
            intento.captura.save(os.path.basename(captura_path), File(f), save=False)

    intento.save()
    print(f"✅ Intento registrado con ID: {intento.id}")
    return intento

def registrar_intento_desde_logC(log_path, captura_path, tiempo_navegacion=60):
    intentos = 0
    while not os.path.exists(log_path) and intentos < 10:
        systime.sleep(2)
        intentos += 1

    if not os.path.exists(log_path):
        print(f"❌ Log no encontrado: {log_path}")
        return None

    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(valor):
        for linea in contenido.splitlines():
            if linea.strip().startswith(valor):
                return linea.split(":", 1)[1].strip()
        return ""

    fecha_str = extraer_linea("Fecha")
    user_agent = extraer_linea("User-Agent")
    url = extraer_linea("URL")
    ids = extraer_linea("Identificadores buscados")
    reconocio = "SÍ" in extraer_linea("Reconocido")

    intento = IntentoReconocimiento.objects.create(
        url=url or "https://desconocida.com",
        identificadores=ids or "No definidos",
        user_agent=user_agent or "Desconocido",
        reconocio=reconocio,
        tiempo_navegacion=tiempo_navegacion
    )

    if os.path.exists(log_path):
        with open(log_path, 'rb') as f:
            intento.log.save(os.path.basename(log_path), File(f), save=False)
    if os.path.exists(captura_path):
        with open(captura_path, 'rb') as f:
            intento.captura.save(os.path.basename(captura_path), File(f), save=False)

    intento.save()
    return intento

def registrar_intento_desde_logD(log_path, captura_path, tiempo_navegacion=60, url_override=None):
    intentos = 0
    while not os.path.exists(log_path) and intentos < 10:
        systime.sleep(2)
        intentos += 1

    if not os.path.exists(log_path):
        print(f"❌ Log no encontrado: {log_path}")
        return None

    with open(log_path, encoding='utf-8') as f:
        contenido = f.read()

    def extraer_linea(valor):
        for linea in contenido.splitlines():
            if linea.strip().startswith(valor):
                return linea.split(":", 1)[1].strip()
        return ""

    fecha_str = extraer_linea("Fecha")
    user_agent = extraer_linea("User-Agent")
    url = extraer_linea("URL") or url_override
    ids = extraer_linea("Identificadores buscados")
    reconocio = "SÍ" in extraer_linea("Reconocido")

    intento = IntentoReconocimiento.objects.create(
        url=url or "https://desconocida.com",
        identificadores=ids or "No definidos",
        user_agent=user_agent or "Desconocido",
        reconocio=reconocio,
        tiempo_navegacion=tiempo_navegacion
    )

    if os.path.exists(log_path):
        with open(log_path, 'rb') as f:
            intento.log.save(os.path.basename(log_path), File(f), save=False)
    if os.path.exists(captura_path):
        with open(captura_path, 'rb') as f:
            intento.captura.save(os.path.basename(captura_path), File(f), save=False)

    intento.save()
    return intento

import os
from django.core.files import File
from django.conf import settings

def registrar_intento_desde_log(log_path, captura_path, tiempo_navegacion=60, url_override=None):
    """
    Crea un IntentoReconocimiento a partir de un log y una captura.
    - log_path y captura_path pueden apuntar a media/logs/... y media/capturas/...
    - Espera hasta 10s a que el archivo log exista.
    - Usa url_override si no puede extraer la URL del log.
    """
    # Esperar a que el log exista
    for _ in range(10):
        if os.path.exists(log_path):
            break
        import time; time.sleep(1)
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

    # Extraer campos
    fecha_str = extraer_linea("Fecha")  # no lo usamos, DateTimeField auto_now_add
    user_agent = extraer_linea("User-Agent") or "Desconocido"
    url = extraer_linea("URL") or url_override or "https://desconocida.com"
    ids = extraer_linea("Identificadores buscados") or ""
    reconocio = "SÍ" in extraer_linea("Reconocido")

    # Crear intento
    intento = IntentoReconocimiento.objects.create(
        url=url,
        identificadores=ids,
        user_agent=user_agent,
        reconocio=reconocio,
        tiempo_navegacion=tiempo_navegacion
    )

    # Guardar archivos si existen
    # Asumimos que log_path y captura_path están en MEDIA_ROOT o son rutas absolutas
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


# ==========================
# API JSON - INTENTOS RECIENTES
# ==========================

@login_required
def intentos_recientes_json(request):
    limite = int(request.GET.get('limite', 20))
    recientes = IntentoReconocimiento.objects.order_by('-fecha')[:limite]
    data = [
        {
            "id": i.id,
            "fecha": i.fecha.strftime("%Y-%m-%d %H:%M:%S"),
            "reconocio": i.reconocio,
            "captura": i.captura.url,
            "tiempo": i.tiempo_navegacion
        } for i in recientes
    ]
    return JsonResponse({"intentos": data})


@csrf_exempt
@require_POST
def marcar_notificado(request):
    ids = json.loads(request.body.decode()).get("ids", [])
    actualizados = IntentoReconocimiento.objects.filter(id__in=ids, notificado=False).update(notificado=True)
    return JsonResponse({"actualizados": actualizados})


# ==========================
# FORMULARIO DE SELECCIÓN RÁPIDA
# ==========================

@login_required
def seleccionar_urlA(request):
    if request.method == "POST":
        form = UrlSeleccionForm(request.POST)
        if form.is_valid():
            url = form.cleaned_data["url"]
            identificadores = ",".join(["usuario", "token", "ip", "correo"])
            repeticiones = "1"
            delay = "0"
            tiempo_navegacion = 60
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

            log_nombre = f"log_seleccion_{timestamp}.txt"
            captura_nombre = log_nombre.replace("log", "captura").replace(".txt", ".png")

            log_path_rel = os.path.join("logs", log_nombre)
            captura_path_rel = os.path.join("capturas", captura_nombre)

            log_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", log_path_rel)
            captura_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", captura_path_rel)

            ruta_script = os.path.join(settings.BASE_DIR, "bank_ghost", "ghost_recon_ultimate.py")
            comando = [
                "python3",
                ruta_script,
                url,
                identificadores,
                repeticiones,
                delay,
                f"seleccion_{timestamp}",
                f"--tiempo={tiempo_navegacion}"
            ]

            try:
                subprocess.Popen(comando)
                systime.sleep(10)
                registrar_intento_desde_log(log_path_abs, captura_path_abs, tiempo_navegacion)
                messages.success(request, f"Ghost Recon activado para: {url}. Resultado visible en el dashboard.")
            except Exception as e:
                messages.error(request, f"Error ejecutando el script: {e}")
            return redirect("dashboard")
    else:
        form = UrlSeleccionForm()

    return render(request, "seleccionar_url.html", {"form": form})


@login_required
def seleccionar_urlB(request):
    if request.method == "POST":
        form = UrlSeleccionForm(request.POST)
        if form.is_valid():
            url = form.cleaned_data["url"]
            identificadores = ",".join(["usuario", "token", "ip", "correo"])
            repeticiones = 1
            delay = 0
            tiempo_navegacion = 60
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            intento_id = f"seleccion_{timestamp}"

            log_nombre = f"log_{intento_id}.txt"
            captura_nombre = f"captura_{intento_id}.png"

            log_path_rel = os.path.join("logs", log_nombre)
            captura_path_rel = os.path.join("capturas", captura_nombre)

            log_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", log_path_rel)
            captura_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", captura_path_rel)

            ruta_script = os.path.join(settings.BASE_DIR, "bank_ghost", "ghost_recon_ultimate.py")
            comando = [
                "python3",
                ruta_script,
                url,
                identificadores,
                str(repeticiones),
                str(delay),
                intento_id,
                f"--tiempo={tiempo_navegacion}",
                "--interactivo"
            ]

            try:
                subprocess.run(comando, cwd=os.path.dirname(ruta_script), check=True)
                intento = registrar_intento_desde_log(log_path_abs, captura_path_abs, tiempo_navegacion)
                if intento:
                    messages.success(request, f"Ghost Recon ejecutado correctamente para {url}. Resultado en dashboard.")
                else:
                    messages.warning(request, f"Se ejecutó Ghost Recon pero no se pudo registrar el intento.")
            except Exception as e:
                messages.error(request, f"Error ejecutando el script: {e}")
            return redirect("dashboard")
    else:
        form = UrlSeleccionForm()

    return render(request, "seleccionar_url.html", {"form": form})

@login_required
def seleccionar_url(request):
    intento_mostrado = None

    if request.method == "POST":
        form = UrlSeleccionForm(request.POST)
        if form.is_valid():
            url = form.cleaned_data["url"]
            identificadores = ",".join(["usuario", "token", "ip", "correo"])
            repeticiones = 1
            delay = 0
            tiempo_navegacion = 60
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            intento_id = f"seleccion_{timestamp}"

            log_nombre = f"log_{intento_id}.txt"
            captura_nombre = f"captura_{intento_id}.png"

            log_path_rel = os.path.join("logs", log_nombre)
            captura_path_rel = os.path.join("capturas", captura_nombre)

            log_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", log_path_rel)
            captura_path_abs = os.path.join(settings.BASE_DIR, "bank_ghost", captura_path_rel)

            ruta_script = os.path.join(settings.BASE_DIR, "bank_ghost", "ghost_recon_ultimate.py")
            comando = [
                "python3",
                ruta_script,
                url,
                identificadores,
                str(repeticiones),
                str(delay),
                intento_id,
                f"--tiempo={tiempo_navegacion}",
                "--interactivo"
            ]

            try:
                subprocess.run(comando, cwd=os.path.dirname(ruta_script), check=True)
                intento = registrar_intento_desde_log(log_path_abs, captura_path_abs, tiempo_navegacion)
                if intento:
                    request.session["ultimo_intento_id"] = intento.id
                    messages.success(request, f"Ghost Recon ejecutado correctamente para {url}. Resultado en dashboard.")
                else:
                    messages.warning(request, f"Se ejecutó Ghost Recon pero no se pudo registrar el intento.")
            except Exception as e:
                messages.error(request, f"Error ejecutando el script: {e}")
            return redirect("seleccionar_url")
    else:
        form = UrlSeleccionForm()
        intento_id = request.session.get("ultimo_intento_id")
        if intento_id:
            try:
                intento_mostrado = IntentoReconocimiento.objects.get(id=intento_id)
            except IntentoReconocimiento.DoesNotExist:
                intento_mostrado = None

    return render(request, "seleccionar_url.html", {
        "form": form,
        "intento": intento_mostrado
    })


@login_required
def ultimos_intentos_json(request):
    intentos = IntentoReconocimiento.objects.order_by('-fecha')[:10]
    datos = [{
        "fecha": intento.fecha.strftime("%Y-%m-%d %H:%M"),
        "reconocio": intento.reconocio,
        "captura": intento.captura.url if intento.captura else None,
        "tiempo": intento.tiempo_navegacion
    } for intento in intentos]
    return JsonResponse(datos, safe=False)


@login_required
def intentos_recientes_json(request):
    limite = int(request.GET.get('limite', 20))
    recientes = IntentoReconocimiento.objects.order_by('-fecha')[:limite]
    data = [
        {
            "id": i.id,
            "fecha": i.fecha.strftime("%Y-%m-%d %H:%M:%S"),
            "reconocio": i.reconocio,
            "captura": i.captura.url,
            "tiempo": i.tiempo_navegacion
        } for i in recientes
    ]
    return JsonResponse({"intentos": data})




from stem import Signal
from stem.control import Controller
from django.contrib.admin.views.decorators import staff_member_required
from django.views.decorators.http import require_POST
from django.shortcuts import redirect
from django.contrib import messages


@staff_member_required
@require_POST
def reiniciar_identidad_tor(request):
    try:
        with Controller.from_port(port=9051) as controller:
            controller.authenticate(password='16:C2CC7421C362FDFF6052BFFB17791359890DCDFF260F0A040E85AC6480')  # 🔐 Aquí tu contraseña
            controller.signal(Signal.NEWNYM)
        messages.success(request, "🧅 Nueva identidad Tor activada.")
    except Exception as e:
        messages.error(request, f"❌ Error al reiniciar Tor: {e}")
    return redirect("dashboard")


def verificar_tor(request):
    import requests
    try:
        r = requests.get("https://check.torproject.org/", proxies={
            "http": "socks5h://127.0.0.1:9050",
            "https": "socks5h://127.0.0.1:9050"
        }, timeout=10000)
        if "Congratulations. This browser is configured to use Tor" in r.text:
            return JsonResponse({"tor": True})
    except Exception as e:
        print("Error verificando Tor:", e)
    return JsonResponse({"tor": False})


def obtener_ip_publica(request):
    import requests
    try:
        r = requests.get("https://api.ipify.org?format=json", timeout=5)
        ip = r.json().get("ip", "Desconocida")
    except:
        ip = "Desconocida"
    return JsonResponse({"ip": ip})


from django.http import JsonResponse
from django.contrib.auth.decorators import login_required

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


