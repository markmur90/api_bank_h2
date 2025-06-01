import json
import sys
import requests

def load_token(json_path, field_name):
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data[field_name]

def send_validation_request(token, url):
    headers = {'Content-Type': 'application/json'}
    payload = {'token': token}
    return requests.post(url, json=payload, headers=headers)

def main():
    if len(sys.argv) not in (2, 3):
        print('Uso: python validate_token.py <ruta_json> [<nombre_campo>]')
        sys.exit(1)
    json_path = sys.argv[1]
    field_name = sys.argv[2] if len(sys.argv) == 3 else 'access_token'
    token = load_token(json_path, field_name)
    url = "https://simulator-api.db.com:443/gw/oidc/token"
    try:
        response = send_validation_request(token, url)
        print(f'→ Status HTTP: {response.status_code}')
        print('→ Cuerpo de la respuesta:')
        print(response.text)
    except Exception as e:
        print(f'¡Vaya! Ocurrió un error al validar el token: {e}')

if __name__ == '__main__':
    main()
