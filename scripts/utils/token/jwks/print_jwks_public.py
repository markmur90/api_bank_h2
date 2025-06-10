import json

with open("jwks_public.json", "r") as f:
    jwks = json.load(f)

print("\n📎 Copia esto y pégalo en el Developer Portal (JWKS):\n")
print(json.dumps(jwks, indent=2))
