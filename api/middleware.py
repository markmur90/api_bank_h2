import logging
from django.utils.deprecation import MiddlewareMixin

from api.configuraciones_api.loader import cargar_variables_entorno

logger = logging.getLogger("django")

class ExceptionLoggingMiddleware(MiddlewareMixin):
    def process_exception(self, request, exception):
        logger.error(f"Error en {request.path}: {str(exception)}", exc_info=True)
        return None

class ConfiguracionPorSesionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        cargar_variables_entorno(request=request)
        return self.get_response(request)