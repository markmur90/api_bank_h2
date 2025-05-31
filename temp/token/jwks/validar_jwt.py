import json
from jwcrypto import jwk, jwt
from jwcrypto.common import JWException

# Cargar JWKS público
with open("jwks_public.json", "r") as f:
    jwks_public = json.load(f)

# Leer el JWT desde el archivo generado
try:
    with open("client_assertion.jwt", "r") as f:
        jwt_string = f.read().strip()
except FileNotFoundError:
    print("❌ No se encontró el archivo 'client_assertion.jwt'")
    exit(1)

# Validar el JWT
try:
    keyset = jwk.JWKSet()
    keyset.import_keyset(json.dumps(jwks_public))

    token = jwt.JWT(key=keyset, jwt=jwt_string)

    print("\n✅ JWT válido. Claims decodificados:")
    print(json.dumps(json.loads(token.claims), indent=2))

except JWException as e:
    print("\n❌ JWT inválido:", str(e))
except Exception as e:
    print("\n⚠️ Error desconocido:", str(e))
