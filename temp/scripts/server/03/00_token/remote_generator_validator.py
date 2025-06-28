#!/usr/bin/env python3
import os, sys, argparse, time, json, requests
from jose import jwt, JWTError
from cryptography.hazmat.primitives import serialization, hashes
from cryptography.hazmat.primitives.asymmetric import ec

def load_or_generate_keys(path):
    priv = os.path.join(path, 'private_key.pem')
    pub = os.path.join(path, 'public_key.pem')
    if not os.path.exists(priv):
        k = ec.generate_private_key(ec.SECP256R1())
        with open(priv,'wb') as f: f.write(k.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
        with open(pub,'wb') as f: f.write(k.public_key().public_bytes(serialization.Encoding.PEM,serialization.PublicFormat.SubjectPublicKeyInfo))
    return open(priv,'rb').read()

def build_assertion(cid, url, pem):
    now = int(time.time())
    claims = {'iss':cid,'sub':cid,'aud':url,'exp':now+300}
    return jwt.encode(claims,pem,algorithm='ES256')

def fetch_jwks(token_url):
    disco = requests.get(token_url.replace('/token','/.well-known/openid-configuration')).json()
    jwks = requests.get(disco['jwks_uri']).json()
    return jwks

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--client-id',required=True)
    p.add_argument('--scope','--scope',default='')
    p.add_argument('--token-url',default='https://api.db.com:443/gw/oidc/token')
    args=p.parse_args()
    base=os.path.dirname(__file__)
    priv=load_or_generate_keys(base)
    assertion=build_assertion(args.client_id,args.token_url,priv)
    data={'grant_type':'client_credentials','client_assertion_type':'urn:ietf:params:oauth:client-assertion-type:jwt-bearer','client_assertion':assertion}
    if args.scope: data['scope']=args.scope
    r=requests.post(args.token_url,data=data); r.raise_for_status()
    resp=r.json()
    with open(os.path.join(base,'access_token.json'),'w') as f: json.dump(resp,f,indent=2)
    jwks=fetch_jwks(args.token_url)
    token=resp['access_token']
    validation={'valid':False}
    try:
        claims=jwt.decode(token, jwks, algorithms=['RS256','ES256'], audience=args.client_id, issuer=args.token_url)
        validation={'valid':True,'claims':claims}
    except JWTError as e:
        validation={'valid':False,'error':str(e)}
    with open(os.path.join(base,'validation.json'),'w') as f: json.dump(validation,f,indent=2)
    print('Proceso remoto completado.')

if __name__=='__main__':
    main()
