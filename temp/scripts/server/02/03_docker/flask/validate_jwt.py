import sys
import json
import jwt
from jwt import ExpiredSignatureError, InvalidSignatureError, InvalidTokenError

SECRET_KEY = 'bar1588623'

def load_token(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
    if path.lower().endswith('.json'):
        data = json.loads(content)
        return data.get('access_token')
    return content

def validate_token(token):
    return jwt.decode(token, SECRET_KEY, algorithms=['HS256'])

def main():
    if len(sys.argv) != 2:
        print('Uso: python validate_jwt.py <ruta_al_token(.json|.txt)>')
        sys.exit(1)
    token_path = sys.argv[1]
    token = load_token(token_path)
    try:
        claims = validate_token(token)
        print('✔ Token válido. Claims:')
        for k, v in claims.items():
            print(f'  {k}: {v}')
    except ExpiredSignatureError:
        print('✖ El token ha expirado.')
    except InvalidSignatureError:
        print('✖ Firma inválida.')
    except InvalidTokenError as e:
        print(f'✖ Token inválido: {e}')

if __name__ == '__main__':
    main()
