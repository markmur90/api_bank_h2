import jwt
import uuid
import time
import requests
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

private_key_pem = b"""
-----BEGIN EC PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgUFzPOdg/E9VDerb0
jrgB9ppQYgq14h+pQafwpKbI+XahRANCAAQ5NLP8rcMmSrB7NyHwJi7eFCYKPney
xioq/VQ0TjOl7Gmjkzu3iAg5lfD0UhSoOrHtphtB2TP1EYH3K7RcFkOn
-----END EC PRIVATE KEY-----
"""

private_key = serialization.load_pem_private_key(
    private_key_pem,
    password=None,
    backend=default_backend()
)

client_id = "c40cd522-3d41-456d-a699-921e0573495b"
aud = "https://simulator-api.db.com/gw/oidc/token"
now = int(time.time())
exp = now + 300  # 5 minutos

payload = {
    "iss": client_id,
    "sub": client_id,
    "aud": aud,
    "exp": exp,
    "jti": str(uuid.uuid4())
}

headers = {
    "alg": "ES256",
    "typ": "JWT"
}

client_assertion = jwt.encode(
    payload,
    private_key,
    algorithm="ES256",
    headers=headers
)

data = {
    "grant_type": "client_credentials",
    "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
    "client_assertion": client_assertion,
    "scope": "sepa_credit_transfers"
}

response = requests.post(
    "https://simulator-api.db.com/gw/oidc/token",
    data=data,
    headers={"Content-Type": "application/x-www-form-urlencoded"}
)

print(response.status_code)
print(response.json())
