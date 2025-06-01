import os
import json
import base64
import hashlib
from datetime import datetime, timedelta
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization, hashes
from jwcrypto import jwk, jwt
from pytz import timezone

SECRET_KEY = 'H858hfhg0ht40588hhfjpfhhd9944940jf'
USUARIO_ID = 'DE86500700100925993805'
ORGANIZATION = 'MIRYA TRADING CO LTD'
VALIDITY_DAYS = 365
CIUDAD = 'Frankfurt'

OUTPUT_DIR = 'credenciales_oauth2'
os.makedirs(OUTPUT_DIR, exist_ok=True)

def guardar_archivo(nombre, contenido, modo='wb'):
    ruta = os.path.join(OUTPUT_DIR, nombre)
    with open(ruta, modo) as f:
        if 'b' in modo:
            f.write(contenido)
        else:
            f.write(contenido + '\n')
    return ruta

def log(mensaje):
    timestamp = datetime.now(timezone('Europe/Berlin')).isoformat()
    linea = f"[{timestamp}] {mensaje}"
    print(linea)
    guardar_archivo('log.txt', linea, modo='a')

# Generar clave privada ECDSA P-256
clave_privada = ec.generate_private_key(ec.SECP256R1())
clave_privada_pem = clave_privada.private_bytes(
    serialization.Encoding.PEM,
    serialization.PrivateFormat.PKCS8,
    serialization.NoEncryption()
)
priv_path = guardar_archivo('clave_privada.pem', clave_privada_pem)
log("Clave privada ECDSA P-256 generada.")

# Generar clave pública
clave_publica = clave_privada.public_key()
clave_publica_pem = clave_publica.public_bytes(
    serialization.Encoding.PEM,
    serialization.PublicFormat.SubjectPublicKeyInfo
)
pub_path = guardar_archivo('clave_publica.pem', clave_publica_pem)
log("Clave pública generada.")

# Crear JWK
clave_jwk = jwk.JWK.from_pem(clave_privada_pem)
jwk_json = clave_jwk.export(private_key=False, as_dict=True)
jwk_json['use'] = 'sig'
jwk_json['alg'] = 'ES256'
jwk_json['kid'] = base64.urlsafe_b64encode(hashlib.sha256(clave_publica_pem).digest()).decode('utf-8')[:16]
jwks = {'keys': [jwk_json]}
jwks_path = guardar_archivo('jwks.json', json.dumps(jwks, indent=2), modo='w')
log("Archivo JWKS generado.")

# Generar JWT client_assertion
ahora = datetime.utcnow()
exp = ahora + timedelta(days=VALIDITY_DAYS)

payload = {
    "iss": USUARIO_ID,
    "sub": USUARIO_ID,
    "aud": "https://api.db.com/token",
    "exp": int(exp.timestamp()),
    "iat": int(ahora.timestamp()),
    "jti": hashlib.sha256(os.urandom(16)).hexdigest()
}
token = jwt.JWT(header={"alg": "ES256", "kid": jwk_json['kid']}, claims=payload)
token.make_signed_token(clave_jwk)
client_assertion = token.serialize()

jwt_path = guardar_archivo('client_assertion.jwt', client_assertion, modo='w')
log("JWT client_assertion generado.")

# Crear resumen
resumen = f"""\
Resumen de Credenciales OAuth2
------------------------------
Organización: {ORGANIZATION}
Usuario: {USUARIO_ID}
Ubicación: {CIUDAD}
Generado: {datetime.now(timezone('Europe/Berlin')).strftime('%Y-%m-%d %H:%M:%S %Z')}
Validez: {VALIDITY_DAYS} días
KID: {jwk_json['kid']}

Archivos generados:
- Clave Privada PEM: {priv_path}
- Clave Pública PEM: {pub_path}
- JWKS JSON: {jwks_path}
- JWT client_assertion: {jwt_path}
- Log: {os.path.join(OUTPUT_DIR, 'log.txt')}
"""

resumen_path = guardar_archivo('resumen.txt', resumen, modo='w')
log("Resumen generado y guardado.")

# Firmar el log usando el SECRET_KEY como HMAC
log_data = open(os.path.join(OUTPUT_DIR, 'log.txt'), 'rb').read()
firma_log = base64.urlsafe_b64encode(
    hashlib.sha256(SECRET_KEY.encode() + log_data).digest()
).decode()
guardar_archivo('firma_log.txt', firma_log, modo='w')
log("Firma HMAC del log generada.")
