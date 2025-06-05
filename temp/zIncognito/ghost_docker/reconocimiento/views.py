import os
import json
import subprocess
from datetime import datetime, time
import time as systime
from django.core.files import File

from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from django.http import HttpResponse, JsonResponse
from django.views.decorators.http import require_POST
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth.decorators import login_required
from django.template.loader import render_to_string
import weasyprint
from django.contrib.admin.views.decorators import staff_member_required

from bank_ghost import settings
from .models import IntentoReconocimiento, UrlMonitoreada
from .forms import EjecucionReconForm, UrlSeleccionForm


# ==========================
# DASHBOARD + INTENTOS
# ==========================

@login_required
def dashboard(request):
    limite = int(request.GET.get("limite", 10))
    totales = IntentoReconocimiento.objects.count()
    reconocidos = IntentoReconocimiento.objects.filter(reconocio=True).count()

    recientes = IntentoReconocimiento.objects.order_by('-fecha')[:limite]

    # Clasificación por origen
    desde_ejecutar = IntentoReconocimiento.objects.filter(log__contains="intento_") | IntentoReconocimiento.objects.filter(log__contains="manual_")
    desde_seleccionar = IntentoReconocimiento.objects.filter(log__contains="seleccion_")

    # Último intento registrado
    ultimo_intento = IntentoReconocimiento.objects.order_by('-fecha').first()

    return render(request, "dashboard.html", {
        "total": totales,
        "reconocidos": reconocidos,
        "recientes": recientes,
        "limite": limite,
        "desde_ejecutar": desde_ejecutar.order_by("-fecha")[:10],
        "desde_seleccionar": desde_seleccionar.order_by("-fecha")[:10],
        "ultimo_intento": ultimo_intento
    })


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
        script_path = os.path.join(settings.BASE_DIR, "reiniciar_sistema_seguro.sh")

        if not os.path.exists(script_path):
            messages.error(request, "❌ El script de reinicio no existe.")
            return redirect("dashboard")

        try:
            subprocess.Popen(["bash", script_path])
            # Redirige a ejecutar con parámetro para mostrar toast
            return redirect("/ejecutar/?reinicio=ok")
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
                    log_path_rel = os.path.join('logs', log_nombre)
                    captura_path_rel = os.path.join('capturas', captura_nombre)
                    log_path_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', log_path_rel)
                    captura_path_abs = os.path.join(settings.BASE_DIR, 'bank_ghost', captura_path_rel)

                    cmd = [
                        'python3',
                        ruta_script,
                        url_final,
                        ids,
                        "1",  # una repetición por llamada
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
def ejecutar_reconocimiento(request):
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
                url_obj, _ = UrlMonitoreada.objects.get_or_create(url=url_manual)
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
                        subprocess.run(cmd, cwd=os.path.dirname(ruta_script), check=True)
                        intento = registrar_intento_desde_log(log_abs, captura_abs, tiempo_navegacion)
                        if intento:
                            print(f"✅ Intento registrado correctamente con ID: {intento.id}")
                        else:
                            print(f"⚠️ Fallo al registrar intento desde: {log_abs}")
                        if r < repeticiones:
                            systime.sleep(delay)
                    except Exception as e:
                        messages.error(request, f"Error en '{url_final}' repetición {r}: {e}")

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

def registrar_intento_desde_log(log_path, captura_path, tiempo_navegacion=60):
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
