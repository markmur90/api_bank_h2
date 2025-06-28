import json
import sys
import jwt
from jwt import ExpiredSignatureError, InvalidSignatureError, InvalidTokenError

def load_token(json_path):
    with open(json_path, 'r') as f:
        data = json.load(f)
    return data.get('access_token')

def load_public_key(path):
    with open(path, 'r') as f:
        return f.read()

def validate_token(token, public_key, audience, issuer):
    return jwt.decode(token, public_key, algorithms=['RS256'], audience=audience, issuer=issuer)

def main():
    if len(sys.argv) != 4:
        print('Uso: python validate_token.py <ruta_json> <ruta_pubkey> <client_id>')
        sys.exit(1)
    json_path, pub_key_path, client_id = sys.argv[1], sys.argv[2], sys.argv[3]
    token = load_token(json_path)
    public_key = load_public_key(pub_key_path)
    try:
        claims = validate_token(token, public_key, audience=client_id, issuer=client_id)
        print('✔ Token válido. Claims:')
        for k, v in claims.items():
            print(f'  {k}: {v}')
    except ExpiredSignatureError:
        print('✖ El token ha expirado.')
    except InvalidSignatureError:
        print('✖ Firma inválida en el token.')
    except InvalidTokenError as e:
        print(f'✖ Token inválido: {e}')

if __name__ == '__main__':
    main()
