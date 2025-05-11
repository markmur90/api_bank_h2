import json
import time
from jwcrypto import jwk, jwt

with open("jwks_private.json", "r") as f:
    jwks_private = json.load(f)

jwk_key = jwk.JWK.from_json(json.dumps(jwks_private["keys"][0]))

client_id = "766ae693-6297-47ea-b825-fd3d07dcf9b6"  # <- cambia esto
token_url = "https://api.db.com/gw/oidc/token"

now = int(time.time())
exp = now + 300

claims = {
    "iss": client_id,
    "sub": client_id,
    "aud": token_url,
    "exp": exp,
    "iat": now,
    "jti": f"jwt-{now}"
}

token = jwt.JWT(
    header={"alg": "ES256", "kid": jwk_key.key_id},
    claims=claims
)
token.make_signed_token(jwk_key)

jwt_assertion = token.serialize()

# Guardar JWT en archivo
with open("client_assertion.jwt", "w") as f:
    f.write(jwt_assertion)

print("✅ JWT firmado generado y guardado en 'client_assertion.jwt'")
