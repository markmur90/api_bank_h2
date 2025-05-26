from django.shortcuts import render, redirect
from django.views import View
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.utils.decorators import method_decorator
from api.authentication.serializers import JWTTokenSerializer
from django.urls import reverse
from api.gpt4.models import Creditor, Transfer
from django.contrib.auth.decorators import login_required
from django.shortcuts import render

class HomeView(View):
    def get(self, request):
        return render(request, 'home.html')

class LoginView(View):
    def get(self, request):
        return render(request, 'login.html')

    def post(self, request):
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        
        if user is not None:
            # Si deseas mantener la autenticación basada en sesiones
            login(request, user)
            
            # Lógica adicional para generar tokens JWT
            tokens = JWTTokenSerializer.get_tokens_for_user(user)
            #return Response(tokens, status=status.HTTP_200_OK)
            return redirect('dashboard')

        return render(request, 'login.html', {'error': 'Credenciales inválidas'})
    


@login_required
def DashboardView(request):
    return render(request, 'dashboard.html', {'user': request.user})

class LogoutView(View):
    def get(self, request):
        logout(request)
        return redirect('home')

@method_decorator(login_required, name='dispatch')
class AuthIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/auth/index.html')

@method_decorator(login_required, name='dispatch')
class CoreIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/core/index.html')

@method_decorator(login_required, name='dispatch')
class AccountsIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/accounts/index.html')

@method_decorator(login_required, name='dispatch')
class TransactionsIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/transactions/index.html')

@method_decorator(login_required, name='dispatch')
class TransfersIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/transfers/index.html')

@method_decorator(login_required, name='dispatch')
class CollectionIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/collection/index.html')

@method_decorator(login_required, name='dispatch')
class SCTIndexView(View):
    def get(self, request):
        return render(request, 'partials/navGeneral/sct/index.html')

@method_decorator(login_required, name='dispatch')
class ReadmeView(View):
    def get(self, request):
        return render(request, 'readme.html')

@method_decorator(login_required, name='dispatch')
class AuthorizeView(View):
    def get(self, request):
        return render(request, 'api/GPT4/oauth2_authorize.html')

@method_decorator(login_required, name='dispatch')
class CallbackView(View):
    def get(self, request):
        return render(request, 'api/GPT4/oauth2_callback.html')

import markdown
from pathlib import Path
from django.shortcuts import render

def mostrar_readme(request):
    readme_path = Path(__file__).resolve().parent.parent / "README_DEPLOY.md"
    contenido_md = readme_path.read_text(encoding="utf-8")
    contenido_html = markdown.markdown(
        contenido_md,
        extensions=["fenced_code", "tables", "toc"]
    )
    return render(request, "readme.html", {"contenido_html": contenido_html})


