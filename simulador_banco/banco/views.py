from datetime import datetime, timedelta
import json

import jwt
from django.conf import settings
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import Group, User
from .forms import (
    AccountMovementForm, UserCreateForm, UserUpdateForm
)
from django.http import JsonResponse, HttpResponse, FileResponse
from django.shortcuts import redirect, render, get_object_or_404
from django.views.decorators.csrf import csrf_exempt

from .models import (
    DebtorAccount,
    AccountMovement,
    OficialBancario,
    OTPChallenge,
)
from .forms import UserCreateWithRoleForm
from django.utils.crypto import get_random_string
from services.transfer_services import TransferService
from django.core.exceptions import ValidationError
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter

# Registros simples en memoria para OAuth y transferencias pendientes
OAUTH_APPROVED = {}
PENDING_TRANSFERS = {}

@csrf_exempt
def recibir_transferencia(request):
    return JsonResponse({"error": "Funcionalidad deshabilitada"}, status=501)

def login_view(request):
    if request.method == "POST":
        username = request.POST["username"]
        password = request.POST["password"]
        user = authenticate(request, username=username, password=password)
        if user:
            login(request, user)
            return redirect("dashboard")
        return render(request, "banco/login.html", {"error": "Credenciales inválidas"})
    return render(request, "banco/login.html")


@login_required
def dashboard_view(request):
    saldo = 10000  # Simulado por ahora
    user = request.user
    template = "banco/dashboard_oficial.html"
    if user.is_superuser:
        template = "banco/dashboard_superuser.html"
    elif user.groups.filter(name="Supervisor").exists():
        template = "banco/dashboard_supervisor.html"
    elif user.groups.filter(name="Gerente").exists():
        template = "banco/dashboard_gerente.html"
    elif user.groups.filter(name="Administrador").exists():
        template = "banco/dashboard_administrador.html"
    return render(request, template, {"saldo": saldo})


@login_required
def transferencia_view(request):
    if request.method == "POST":
        destinatario = request.POST["destinatario"]
        monto = float(request.POST["monto"])
        # Aquí guardaríamos la transferencia
        return redirect("dashboard")
    return render(request, "banco/transferencia.html")


def registro_view(request):
    if request.method == "POST":
        form = UserCreationForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect("login")
    else:
        form = UserCreationForm()
    return render(request, "banco/registro.html", {"form": form})


@login_required
def logout_view(request):
    """End the current user session and redirect to login."""
    logout(request)
    return redirect("login")


@login_required
@user_passes_test(lambda u: u.is_superuser)
def toggle_user_active(request, user_id):
    user = get_object_or_404(User, id=user_id)
    if user != request.user:
        user.is_active = not user.is_active
        user.save()
    return redirect("user_management")


# banco/views.py
import jwt
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
import json
from datetime import datetime, timedelta
from .models import OficialBancario

# Clave usada para firmar JWT desde vistas o comandos
JWT_SECRET = getattr(settings, 'JWT_SECRET_KEY', settings.SECRET_KEY)
ALGORITHM = 'HS256'

@csrf_exempt
def generar_token(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)
    
    data = json.loads(request.body.decode())
    username = data.get('username')
    password = data.get('password')

    try:
        oficial = OficialBancario.objects.get(username=username)
        if not oficial.check_password(password):
            return JsonResponse({'error': 'Credenciales inválidas'}, status=401)
    except OficialBancario.DoesNotExist:
        return JsonResponse({'error': 'Usuario no encontrado'}, status=404)

    payload = {
        'usuario': username,
        'exp': datetime.utcnow() + timedelta(hours=2)
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=ALGORITHM)
    return JsonResponse({'token': token})




def oauth2_authorize(request):
    """Endpoint de autorización simulado.

    Marca un ``payment_id`` como autorizado para posteriores
    operaciones protegidas por OAuth.
    """
    if request.method != 'GET':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    payment_id = request.GET.get('payment_id')
    if not payment_id:
        return JsonResponse({'error': 'payment_id requerido'}, status=400)

    OAUTH_APPROVED[payment_id] = True
    return JsonResponse({'result': 'authorized', 'payment_id': payment_id})




# banco/views.py
from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from .models import OficialBancario  # o el modelo que uses
import json

@csrf_exempt
def crear_transferencia(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    if not hasattr(request, 'user_jwt'):
        return JsonResponse({'error': 'Autenticación requerida'}, status=401)

    data = json.loads(request.body.decode())
    monto = data.get('monto')
    destino = data.get('destino')

    usuario = request.user_jwt['usuario']
    oficial = OficialBancario.objects.get(username=usuario)

    # Validaciones básicas
    if not monto or not destino:
        return JsonResponse({'error': 'Faltan datos'}, status=400)

    # Lógica simulada eliminada
    return JsonResponse({'estado': 'ok', 'payment_id': 'SIMULATED'})

@csrf_exempt
def api_challenge(request):
    """Genera un OTP para una transferencia simulada."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    if not hasattr(request, 'user_jwt'):
        return JsonResponse({'error': 'Autenticación requerida'}, status=401)

    data = json.loads(request.body.decode())
    payment_id = data.get('payment_id')
    if not payment_id:
        return JsonResponse({'error': 'payment_id requerido'}, status=400)

    if not OAUTH_APPROVED.get(payment_id):
        return JsonResponse({'error': 'OAuth no aprobado'}, status=403)

    otp = get_random_string(6, allowed_chars='0123456789')
    challenge = OTPChallenge.objects.create(payment_id=payment_id, otp=otp)
    return JsonResponse({'challenge_id': str(challenge.challenge_id), 'otp': otp})


@csrf_exempt
def api_send_transfer(request):
    """Procesa la transferencia validando el OTP."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    if not hasattr(request, 'user_jwt'):
        return JsonResponse({'error': 'Autenticación requerida'}, status=401)

    data = json.loads(request.body.decode())
    payment_id = data.get('payment_id')
    otp = data.get('otp')
    totp_code = data.get('totp')

    from .totp_utils import verify_totp
    if not verify_totp(str(totp_code)):
        return JsonResponse({'error': 'TOTP inválido'}, status=400)
    
    try:
        challenge = OTPChallenge.objects.get(payment_id=payment_id, otp=otp, status='CREATED')
    except OTPChallenge.DoesNotExist:
        return JsonResponse({'error': 'OTP inválido'}, status=400)

    try:
        transfer = TransferService.ingest_transfer(challenge.transfer_data or {})
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=400)

    challenge.status = 'USED'
    challenge.save()
    return JsonResponse({'payment_id': transfer.payment_id, 'status': transfer.status})

def api_status_transfer(request):
    payment_id = request.GET.get('payment_id')
    if not payment_id:
        return JsonResponse({'error': 'payment_id requerido'}, status=400)
    return JsonResponse({'payment_id': payment_id, 'status': 'RJCT'})


def transfer_simulator_frontend(request):
    return render(request, 'banco/transfer_simulator_frontend.html')


@csrf_exempt
def api_transfer_incoming(request):
    """Recibe transferencias de sistemas externos con verificación OTP."""
    if request.method != 'POST':
        return JsonResponse({'error': 'Método no permitido'}, status=405)

    # Autenticación mediante JWT o sesión activa
    if not hasattr(request, 'user_jwt') and not request.user.is_authenticated:
        return JsonResponse({'error': 'Autenticación requerida'}, status=401)

    try:
        data = json.loads(request.body.decode())
    except json.JSONDecodeError:
        return JsonResponse({'error': 'JSON inválido'}, status=400)

    payment_id = data.get('payment_id')
    otp = data.get('otp')
    totp_code = data.get('totp')

    if not otp:
        if not payment_id:
            return JsonResponse({'error': 'payment_id requerido'}, status=400)
        otp_val = get_random_string(6, allowed_chars='0123456789')
        challenge = OTPChallenge.objects.create(payment_id=payment_id, otp=otp_val)
        return JsonResponse({
            'challenge_id': str(challenge.challenge_id),
            'otp_required': True,
            'otp': otp_val
        }, status=202)

    from .totp_utils import verify_totp
    if not verify_totp(str(totp_code)):
        return JsonResponse({'error': 'TOTP inválido'}, status=400)

    try:
        challenge = OTPChallenge.objects.get(payment_id=payment_id, otp=otp, status='CREATED')
    except OTPChallenge.DoesNotExist:
        return JsonResponse({'error': 'OTP inválido'}, status=400)

    challenge.status = 'USED'
    challenge.save()

    try:
        transfer = TransferService.ingest_transfer(data)
    except ValidationError as e:
        return JsonResponse({'error': str(e)}, status=400)

    return JsonResponse({'payment_id': transfer.payment_id, 'status': transfer.status})


# ---------------------------------------------------------------------------
# Gestión de usuarios (solo para superusuario)
# ---------------------------------------------------------------------------
@login_required
def user_list(request):
    if not request.user.is_superuser:
        return redirect('dashboard')
    users = User.objects.all()
    return render(request, 'banco/user_list.html', {'users': users})


@login_required
def user_create(request):
    if not request.user.is_superuser:
        return redirect('dashboard')
    if request.method == 'POST':
        form = UserCreateForm(request.POST)
        if form.is_valid():
            form.save()
            return redirect('user_list')
    else:
        form = UserCreateForm()
    return render(request, 'banco/user_form.html', {'form': form, 'create': True})


@login_required
def user_edit(request, pk):
    if not request.user.is_superuser:
        return redirect('dashboard')
    user = User.objects.get(pk=pk)
    if request.method == 'POST':
        form = UserUpdateForm(request.POST, instance=user)
        if form.is_valid():
            form.save()
            return redirect('user_list')
    else:
        initial = {'role': user.groups.first()}
        form = UserUpdateForm(instance=user, initial=initial)
    return render(request, 'banco/user_form.html', {'form': form, 'edit': True})


from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.models import User, Group
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib import messages
from .forms import UserCreateWithRoleForm

@login_required
@user_passes_test(lambda u: u.is_superuser)
def user_management(request):
    users = User.objects.all()
    all_groups = Group.objects.all().order_by('name')
    if request.method == "POST":
        form = UserCreateWithRoleForm(request.POST)
        if form.is_valid():
            user = form.save()
            group = form.cleaned_data["role"]
            user.groups.add(group)
            return redirect("user_management")
    else:
        form = UserCreateWithRoleForm()
    return render(request, "banco/user_management.html", {
        "form": form,
        "users": users,
        "all_groups": all_groups,
    })

@login_required
@user_passes_test(lambda u: u.is_superuser)
def update_user_role(request, user_id):
    user = get_object_or_404(User, pk=user_id)
    if request.method == "POST":
        group_id = request.POST.get("group")
        user.groups.clear()
        if group_id:
            group = get_object_or_404(Group, pk=group_id)
            user.groups.add(group)
        messages.success(request, f"El rol de «{user.username}» se actualizó correctamente.")
    return redirect("user_management")


@login_required
def account_movement_create(request, account_id, tipo):
    """Registra un depósito o pago en una cuenta de deudor."""
    account = get_object_or_404(DebtorAccount, pk=account_id)
    if request.method == "POST":
        form = AccountMovementForm(request.POST)
        if form.is_valid():
            movimiento = form.save(commit=False)
            movimiento.account = account
            movimiento.tipo = tipo
            movimiento.save()
            return redirect('estado_cuenta', account_id=account.id)
    else:
        form = AccountMovementForm(initial={'tipo': tipo})
    return render(request, 'banco/movimiento_form.html', {
        'form': form,
        'account': account,
        'tipo': tipo,
    })


@login_required
def estado_cuenta(request, account_id):
    """Muestra el estado de cuenta de una cuenta de deudor."""
    account = get_object_or_404(DebtorAccount, pk=account_id)
    movimientos = account.movimientos.order_by('-fecha')
    start = request.GET.get('inicio')
    end = request.GET.get('fin')
    if start:
        movimientos = movimientos.filter(fecha__date__gte=start)
    if end:
        movimientos = movimientos.filter(fecha__date__lte=end)
    return render(request, 'banco/estado_deudor.html', {
        'account': account,
        'movimientos': movimientos,
    })


@login_required
def estado_cuenta_pdf(request, account_id):
    """Exporta el estado de cuenta en PDF."""
    account = get_object_or_404(DebtorAccount, pk=account_id)
    movimientos = account.movimientos.order_by('fecha')
    start = request.GET.get('inicio')
    end = request.GET.get('fin')
    if start:
        movimientos = movimientos.filter(fecha__date__gte=start)
    if end:
        movimientos = movimientos.filter(fecha__date__lte=end)

    from io import BytesIO
    from reportlab.lib.pagesizes import letter
    from reportlab.pdfgen import canvas

    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=letter)
    p.drawString(100, 750, f"Estado de cuenta de {account.debtor.name}")
    y = 720
    for mov in movimientos:
        p.drawString(80, y, f"{mov.fecha.strftime('%Y-%m-%d %H:%M')} - {mov.tipo} - {mov.monto}")
        y -= 20
        if y < 50:
            p.showPage()
            y = 750
    p.drawString(80, y-20, f"Saldo actual: {account.balance}")
    p.showPage()
    p.save()
    buffer.seek(0)
    return FileResponse(buffer, as_attachment=True, filename='estado.pdf')

