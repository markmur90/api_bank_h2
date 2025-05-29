import json
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
from jwcrypto import jwk
import uuid

# 1. Generar clave privada ECDSA P-256
private_key = ec.generate_private_key(ec.SECP256R1())

# 2. Serializar la clave privada a formato PEM
private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

with open("ecdsa_private_key.pem", "wb") as f:
    f.write(private_pem)
print("✅ Clave privada guardada en: ecdsa_private_key.pem")

# 3. Obtener clave pública desde la privada
public_key = private_key.public_key()

# 4. Serializar la clave pública a formato PEM
public_pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)

with open("ecdsa_public_key.pem", "wb") as f:
    f.write(public_pem)
print("✅ Clave pública guardada en: ecdsa_public_key.pem")

# 5. Generar JWK público compatible con JWKS (para Deutsche Bank)
jwk_key = jwk.JWK.from_pem(public_pem)
jwk_key.update({
    "alg": "ES256",
    "use": "sig",
    "kid": str(uuid.uuid4())
})

jwks = {"keys": [json.loads(jwk_key.export(private_key=False))]}

with open("jwks_public.json", "w") as f:
    f.write(json.dumps(jwks, indent=2))

print("✅ JWKS guardado en: jwks_public.json")
