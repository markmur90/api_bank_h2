def entorno_actual(request):
    return {
        'entornos': ['local', 'sandbox', 'produccion'],
        'entorno_actual': request.session.get('entorno_actual', 'produccion')
    }
