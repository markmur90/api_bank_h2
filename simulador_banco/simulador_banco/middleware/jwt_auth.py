# simulador_banco/middleware/jwt_auth.py
import os
import jwt
from django.http import JsonResponse

SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'change-me')
ALGORITHM = 'HS256'


EXEMPT_PATHS = {
    '/api/login/',
    '/api/token',
    '/frontend/transfer',
}

# Only enforce JWT on API endpoints.
API_PREFIX = '/api/'


class JWTAuthenticationMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path in EXEMPT_PATHS or not request.path.startswith(API_PREFIX):
            return self.get_response(request)
        
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        if not auth_header.startswith('Bearer '):
            return JsonResponse({'error': 'Missing or invalid Authorization header'}, status=401)
        
        token = auth_header.split(' ')[1]
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            request.user_jwt = payload  # Acceso al payload en views
        except jwt.ExpiredSignatureError:
            return JsonResponse({'error': 'Token expired'}, status=401)
        except jwt.InvalidTokenError:
            return JsonResponse({'error': 'Invalid token'}, status=401)

        return self.get_response(request)
