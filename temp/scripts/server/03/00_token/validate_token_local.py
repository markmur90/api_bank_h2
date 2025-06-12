#!/usr/bin/env python3
import os, sys, argparse, json
from jose import jwt, JWTError

def main():
    p = argparse.ArgumentParser(); p.add_argument('--token-file', default='access_token.json'); p.add_argument('--public-key', default='public_key.pem'); p.add_argument('--aud', required=True); p.add_argument('--iss', required=True)
    args = p.parse_args()
    with open(args.token_file) as f: token = json.load(f)['access_token']
    pub = open(args.public_key, 'rb').read()
    result = {}
    try:
        claims = jwt.decode(token, pub, algorithms=['ES256'], audience=args.aud, issuer=args.iss)
        result['valid'] = True
        result['claims'] = claims
    except JWTError as e:
        result['valid'] = False
        result['error'] = str(e)
    base = os.path.dirname(__file__)
    with open(os.path.join(base, 'validation.json'), 'w') as f: json.dump(result, f, indent=2)
    with open(os.path.join(base, 'validation.txt'), 'w') as f:
        if result['valid']:
            f.write('Token válido. Claims:\n' + json.dumps(result['claims'], indent=2))
        else:
            f.write('Token inválido:\n' + result['error'])
    print('Validación completada.')

if __name__ == '__main__':
    main()
