import jwt
from datetime import datetime, timedelta, timezone
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

USER_ID = 'DE86500700100925993805'
PRIVATE_KEY_PATH = 'private.pem'
PUBLIC_KEY_PATH = 'public.pem'

def generar_claves():
    clave_privada = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    pem_priv = clave_privada.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    with open(PRIVATE_KEY_PATH, 'wb') as f:
        f.write(pem_priv)
    clave_publica = clave_privada.public_key()
    pem_pub = clave_publica.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    with open(PUBLIC_KEY_PATH, 'wb') as f:
        f.write(pem_pub)

def generar_token(user_id):
    with open(PRIVATE_KEY_PATH, 'r') as f:
        private_key = f.read()
    ahora = datetime.now(timezone.utc)
    payload = {
        'user_id': user_id,
        'iat': ahora,
        'exp': ahora + timedelta(hours=24)
    }
    token = jwt.encode(payload, private_key, algorithm='RS256')
    with open('generated_token_pem.txt', 'w') as token_file:
        token_file.write(token)
    print(f"Generated JWT Token: {token}")
    return token

if __name__ == '__main__':
    generar_claves()
    generar_token(USER_ID)
