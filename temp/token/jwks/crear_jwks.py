from jwcrypto import jwk
import json

# Generar clave EC P-256
key = jwk.JWK.generate(kty='EC', crv='P-256')

# Exportar clave pública
public_jwk = key.export(private_key=False)
jwks = {"keys": [json.loads(public_jwk)]}

# Exportar clave privada
private_jwk = key.export(private_key=True)
jwks_private = {"keys": [json.loads(private_jwk)]}

# Guardar archivos
with open("jwks_public.json", "w") as pub_file:
    json.dump(jwks, pub_file, indent=2)

with open("jwks_private.json", "w") as priv_file:
    json.dump(jwks_private, priv_file, indent=2)

print("✅ JWKS generado:")
print("\n🔓 JWKS público (sube esto al portal de DB):")
print(json.dumps(jwks, indent=2))

print("\n🔐 JWKS privado (guárdalo en tu sistema seguro):")
print(json.dumps(jwks_private, indent=2))
