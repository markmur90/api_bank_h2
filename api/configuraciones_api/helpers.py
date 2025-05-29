from api.configuraciones_api.models import ConfiguracionAPI

def obtener_config(nombre, entorno='produccion', por_defecto=None):
    try:
        return ConfiguracionAPI.objects.get(nombre=nombre, entorno=entorno, activo=True).valor
    except ConfiguracionAPI.DoesNotExist:
        return por_defecto

def get_conf(clave, default=None):
    from django.conf import settings
    entorno = getattr(settings, "DJANGO_ENV", "local")
    return obtener_config(clave, entorno=entorno, por_defecto=default)
