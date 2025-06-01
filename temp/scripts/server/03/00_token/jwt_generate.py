from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec
import json
import base64

# (Este fragmento asume que ya existe private_key.pem)

key = ec.generate_private_key(ec.SECP256R1())
numbers = key.public_key().public_numbers()
x_bytes = numbers.x.to_bytes(32, 'big')
y_bytes = numbers.y.to_bytes(32, 'big')
x_b64 = base64.urlsafe_b64encode(x_bytes).decode().rstrip('=')
y_b64 = base64.urlsafe_b64encode(y_bytes).decode().rstrip('=')

jwk = {
    "keys": [{
        "kty": "EC",
        "use": "sig",
        "crv": "P-256",
        "kid": "db-key-1",
        "x": x_b64,
        "y": y_b64
    }]
}

with open('jwks.json','w') as f:
    json.dump(jwk, f, indent=2)
