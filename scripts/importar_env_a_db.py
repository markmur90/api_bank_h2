import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from api.configuraciones_api.models import ConfiguracionAPI

def importar_env(env_file_path, entorno='production'):
    if not os.path.isfile(env_file_path):
        print(f"❌ No se encontró el archivo: {env_file_path}")
        return

    with open(env_file_path, 'r') as file:
        for linea in file:
            linea = linea.strip()
            if not linea or linea.startswith("#"):
                continue
            if '=' not in linea:
                print(f"⚠️  Línea inválida: {linea}")
                continue

            nombre, valor = linea.split('=', 1)
            nombre = nombre.strip()
            valor = valor.strip().strip('"').strip("'")

            obj, creado = ConfiguracionAPI.objects.update_or_create(
                entorno=entorno,
                nombre=nombre,
                defaults={'valor': valor, 'activo': True}
            )
            estado = "➕ creado" if creado else "✏️ actualizado"
            print(f"{estado}: {nombre} = {valor[:50]}{'...' if len(valor) > 50 else ''}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python importar_env_a_db.py ruta/.env [entorno]")
    else:
        archivo = sys.argv[1]
        entorno = sys.argv[2] if len(sys.argv) > 2 else 'production'
        importar_env(archivo, entorno)
