# filepath: $HOME/Documentos/GitHub/swiftapi3/api/core/middleware.py
from threading import local

_user = local()

class CurrentUserMiddleware:
    """
    Middleware para almacenar el usuario actual en una variable de contexto.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        _user.value = request.user if request.user.is_authenticated else None
        response = self.get_response(request)
        return response

    @staticmethod
    def get_current_user():
        return getattr(_user, 'value', None)

from django.utils import timezone
from django.contrib.auth import logout
from django.shortcuts import redirect

class SessionExpiryMiddleware:
    """
    Middleware que comprueba en cada petición si la sesión ha expirado.
    Si el usuario está autenticado pero la sesión ya no es válida,
    hace logout y redirige a la vista de login.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        user = getattr(request, 'user', None)
        if user is not None and user.is_authenticated:
            expiry = request.session.get_expiry_date()
            if expiry < timezone.now():
                logout(request)
                return redirect('login')
        return self.get_response(request)


class ExceptionLoggingMiddleware:
    """
    Ejemplo de middleware que intercepta excepciones no controladas
    y las guarda en un log o las serializa para enviarlas a un sistema
    externo de monitoreo.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            response = self.get_response(request)
        except Exception as exc:
            # Aquí va tu lógica para registrar la excepción:
            # p. ej. logger.error(f"Error en {request.path}: {exc}")
            raise   # o si quieres manejarla, devuelve un HttpResponse
        return response


class CurrentUserMiddleware:
    """
    Middleware que inyecta en cada request el usuario actual en un contexto
    global para poder acceder a él desde cualquier parte del código, p. ej.
    en señales o tareas background.
    """
    _user = None

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        CurrentUserMiddleware._user = getattr(request, 'user', None)
        response = self.get_response(request)
        return response

    @classmethod
    def get_current_user(cls):
        return cls._user
