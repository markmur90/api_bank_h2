#!/usr/bin/env python3
import os, sys, argparse, time, json
import requests
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import ec
from jose import jwt

def load_or_generate_keys(path):
    priv_file = os.path.join(path, 'private_key.pem')
    pub_file = os.path.join(path, 'public_key.pem')
    if not os.path.exists(priv_file):
        key = ec.generate_private_key(ec.SECP256R1())
        priv = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption())
        pub = key.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
        with open(priv_file, 'wb') as f: f.write(priv)
        with open(pub_file, 'wb') as f: f.write(pub)
    with open(priv_file, 'rb') as f: priv = f.read()
    return priv

def build_assertion(client_id, token_url, private_pem):
    now = int(time.time())
    claims = {'iss': client_id, 'sub': client_id, 'aud': token_url, 'exp': now + 300}
    return jwt.encode(claims, private_pem, algorithm='ES256')

def main():
    p = argparse.ArgumentParser(); p.add_argument('--client-id', required=True); p.add_argument('--scope', default=''); p.add_argument('--token-url', default='https://api.db.com:443/gw/oidc/token')
    args = p.parse_args()
    base = os.path.dirname(__file__)
    private_pem = load_or_generate_keys(base)
    assertion = build_assertion(args.client_id, args.token_url, private_pem)
    data = {'grant_type':'client_credentials','client_assertion_type':'urn:ietf:params:oauth:client-assertion-type:jwt-bearer','client_assertion':assertion}
    if args.scope: data['scope'] = args.scope
    r = requests.post(args.token_url, data=data)
    r.raise_for_status()
    token_resp = r.json()
    with open(os.path.join(base, 'access_token.json'), 'w') as f: json.dump(token_resp, f, indent=2)
    with open(os.path.join(base, 'access_token.txt'), 'w') as f: f.write(token_resp.get('access_token',''))
    print('Access token generado y guardado.')

if __name__ == '__main__':
    main()
