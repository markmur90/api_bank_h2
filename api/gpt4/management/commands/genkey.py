import os
import json
import uuid
from datetime import datetime
from django.core.management.base import BaseCommand
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives import serialization
from jwcrypto import jwk
import getpass

from api.gpt4.models import ClaveGenerada

class Command(BaseCommand):
    help = "Genera clave privada ECDSA P-256, clave pública y JWKS para client_assertion OAuth2"

    def handle(self, *args, **kwargs):
        base_dir = "keys"
        log_dir = "logs"
        os.makedirs(base_dir, exist_ok=True)
        os.makedirs(log_dir, exist_ok=True)
        log_path = os.path.join(log_dir, "clave_gen.log")

        files = {
            "private": os.path.join(base_dir, "ecdsa_private_key.pem"),
            "public": os.path.join(base_dir, "ecdsa_public_key.pem"),
            "jwks": os.path.join(base_dir, "jwks_public.json")
        }

        usuario = getpass.getuser()

        try:
            existentes = [f for f in files.values() if os.path.exists(f)]
            if existentes:
                self.stdout.write(self.style.WARNING("⚠️  Ya existen los siguientes archivos:"))
                for f in existentes:
                    self.stdout.write(f"  - {f}")
                confirm = input("¿Deseas sobrescribirlos? (sí/no): ").strip().lower()
                if confirm not in ("si", "sí", "s", "yes", "y"):
                    ClaveGenerada.objects.create(
                        usuario=usuario,
                        estado="CANCELADO"
                    )
                    self.stdout.write(self.style.NOTICE("🛑 Operación cancelada. Registro creado."))
                    return

            # 1. Clave privada
            private_key = ec.generate_private_key(ec.SECP256R1())
            private_pem = private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
            with open(files["private"], "wb") as f:
                f.write(private_pem)
            self.stdout.write(self.style.SUCCESS(f"✅ Clave privada: {files['private']}"))

            # 2. Clave pública
            public_key = private_key.public_key()
            public_pem = public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )
            with open(files["public"], "wb") as f:
                f.write(public_pem)
            self.stdout.write(self.style.SUCCESS(f"✅ Clave pública: {files['public']}"))

            # 3. JWKS
            kid = str(uuid.uuid4())
            jwk_key = jwk.JWK.from_pem(public_pem)
            jwk_key.update({
                "alg": "ES256",
                "use": "sig",
                "kid": kid
            })
            jwks = {"keys": [json.loads(jwk_key.export(private_key=False))]}
            with open(files["jwks"], "w") as f:
                f.write(json.dumps(jwks, indent=2))
            self.stdout.write(self.style.SUCCESS(f"✅ JWKS generado con kid={kid}: {files['jwks']}"))

            # 4. Log a archivo
            log_entry = {
                "timestamp": datetime.now().isoformat(),
                "usuario": usuario,
                "archivos": files,
                "kid": kid
            }
            with open(log_path, "a", encoding="utf-8") as lf:
                lf.write(json.dumps(log_entry, indent=2) + "\n")
            self.stdout.write(self.style.SUCCESS(f"📝 Log escrito en: {log_path}"))

            # 5. Log en base de datos
            ClaveGenerada.objects.create(
                usuario=usuario,
                estado="EXITO",
                kid=kid,
                path_privada=files["private"],
                path_publica=files["public"],
                path_jwks=files["jwks"]
            )
            self.stdout.write(self.style.SUCCESS("📥 Registro guardado en la base de datos."))

            # 6. Actualizar settings.py con el nuevo KID
            settings_path = os.path.join("config", "settings.py")
            if os.path.exists(settings_path):
                try:
                    with open(settings_path, "r", encoding="utf-8") as f:
                        lines = f.readlines()

                    updated = False
                    for i, line in enumerate(lines):
                        if line.startswith("PRIVATE_KEY_KID"):
                            lines[i] = f"PRIVATE_KEY_KID = '{kid}'\n"
                            updated = True
                            break

                    if not updated:
                        lines.append(f"\nPRIVATE_KEY_KID = '{kid}'\n")

                    with open(settings_path, "w", encoding="utf-8") as f:
                        f.writelines(lines)

                    self.stdout.write(self.style.SUCCESS(f"🛠️ settings.py actualizado con PRIVATE_KEY_KID = '{kid}'"))

                except Exception as e:
                    self.stdout.write(self.style.WARNING(f"⚠️ No se pudo actualizar settings.py: {str(e)}"))
            else:
                self.stdout.write(self.style.WARNING("⚠️ No se encontró config/settings.py para registrar el KID."))

        except Exception as e:
            ClaveGenerada.objects.create(
                usuario=usuario,
                estado="ERROR",
                mensaje_error=str(e)
            )
            self.stdout.write(self.style.ERROR(f"❌ Error durante ejecución: {str(e)}"))
            raise
