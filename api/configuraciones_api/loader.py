import os
from django.core.exceptions import ImproperlyConfigured

# def cargar_variables_entorno(entorno='production'):
#     try:
#         from api.configuraciones_api.models import ConfiguracionAPI
#         configuraciones = ConfiguracionAPI.objects.filter(entorno=entorno, activo=True)
#         for config in configuraciones:
#             if config.nombre not in os.environ:
#                 os.environ[config.nombre] = config.valor
#     except Exception as e:
#         if 'no such table' in str(e).lower():
#             pass  # Primera migración: ignorar
#         else:
#             raise ImproperlyConfigured(f"Error cargando configuración desde BD: {e}")


def cargar_variables_entorno(entorno=None, request=None):
    from api.configuraciones_api.models import ConfiguracionAPI

    if request and 'entorno_actual' in request.session:
        entorno = request.session['entorno_actual']
    elif not entorno:
        entorno = os.getenv('DJANGO_ENV', 'production')

    configuraciones = ConfiguracionAPI.objects.filter(entorno=entorno, activo=True)
    for config in configuraciones:
        if config.nombre not in os.environ:
            os.environ[config.nombre] = config.valor
