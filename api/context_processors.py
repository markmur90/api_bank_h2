def entorno_actual(request):
    return {
        'entorno_actual': request.session.get('entorno_actual', 'produccion')
    }
