import os
import sys
import django

# Configurar Django
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
            
            # Truncar valor si es demasiado largo (máximo 500 caracteres)
            if len(valor) > 500:
                valor_truncado = valor[:500] + "..."
                print(f"⚠️  Valor truncado para {nombre}: {valor[:500]}...")
                valor = valor_truncado

            try:
                obj, creado = ConfiguracionAPI.objects.update_or_create(
                    entorno=entorno,
                    nombre=nombre,
                    defaults={'valor': valor, 'activo': True}
                )
                estado = "➕ creado" if creado else "✏️ actualizado"
                print(f"{estado}: {nombre} = {valor[:500]}{'...' if len(valor) > 50 else ''}")
            except Exception as e:
                print(f"❌ Error en línea: {linea}")
                print(f"   Error: {e}")

def importar_variables_entorno():
    """Importa todas las variables de entorno a la base de datos ConfiguracionAPI"""
    
    # Obtener el entorno actual
    entorno = os.getenv('DJANGO_ENV', 'production')
    
    # Lista completa de variables que deben estar en BD
    variables_bd = [
        # Configuración OAUTH2 y API
        'CLIENT_ID', 'CLIENT_SECRET', 'SCOPE', 'REDIRECT_URI', 'ORIGIN', 'ACCESS_TOKEN',
        'TOKEN_URL', 'OTP_URL', 'AUTH_URL', 'API_URL', 'AUTHORIZE_URL',
        
        # URLs y endpoints
        'BASE_URL', 'LOGIN_URL', 'TRANSFER_URL', 'STATUS_URL', 'VERIFY_URL',
        'SIMULADOR_API_URL', 'SIMULADOR_LOGIN_URL', 'SIMULADOR_VERIFY_URL',
        'TOKEN_ENDPOINT', 'CHALLENGE_URL',
        
        # Paths
        'TOKEN_PATH', 'AUTH_PATH', 'SEND_PATH', 'STATUS_PATH', 'VERIFY_PATH',
        'API_TRANSFER_PATH',
        
        # Autenticación y seguridad
        'JWT_SIGNING_KEY', 'JWT_VERIFYING_KEY', 'SIMULADOR_SECRET_KEY', 'TOTP_SECRET',
        
        # Credenciales
        'BANK_USER', 'BANK_PASS', 'SIMULADOR_USERNAME', 'SIMULADOR_PASSWORD',
        
        # Configuración del servidor
        'DNS_BANCO', 'DOMINIO_BANCO', 'MOCK_PORT', 'RED_SEGURA_PREFIX', 'ALLOW_FAKE_BANK',
        'TIMEOUT', 'TIMEOUT_REQUEST',
        
        # SSH
        # 'SSH_HOST', 'SSH_PORT', 'SSH_USER', 'SSH_KEY_PATH', 'SSH_PASSWORD',
        
        # SSL
        'ENABLE_CERT_PINNING_FOR_BANK', 'REQUESTS_CA_BUNDLE', 'FORCE_INSECURE_SSL_FOR_BANK', 'BANK_CERT_PIN_SHA256',
        'BASE_DIR',
        
        # Pushtan
        'USE_PUSHTAN_AUTO', 'PUSHTAN_ENABLED', 'AUTO_AUTHORIZE_TRANSFERS',
        'PUSHTAN_TIMEOUT_SECONDS', 'PUSHTAN_RETRY_INTERVAL', 'MAX_TRANSFER_RETRIES',
        
        # SEPA
        'SEPA_CREATE_TRANSFER_URL', 'SEPA_STATUS_URL', 'SEPA_DETAILS_URL',
        'SEPA_CANCEL_URL', 'SEPA_RETRY_SCA_URL',
        
        # Webhook
        'WEBHOOK_SECRET',
        
        # Variables específicas
        'BANK_TIMEOUT', 'BANK_HOST', 'BANK_PORT', 'BANK_ALLOW_MOCK', 'BANK_VERIFY_SSL',
        'REFRESH_TOKEN',
    ]
    
    print(f"🔄 Importando variables para entorno: {entorno}")
    
    for var_name in variables_bd:
        valor = os.getenv(var_name)
        if valor is not None:
            obj, creado = ConfiguracionAPI.objects.update_or_create(
                nombre=var_name,
                entorno=entorno,
                defaults={
                    'valor': valor,
                    'descripcion': f'Variable {var_name} importada desde .env',
                    'activo': True
                }
            )
            status = "✅ Creada" if creado else "🔄 Actualizada"
            print(f"{status}: {var_name} = {valor[:50]}{'...' if len(valor) > 50 else ''}")
        else:
            print(f"⚠️  Variable no encontrada: {var_name}")
    
    print(f"✅ Importación completada para entorno: {entorno}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Uso: python3 importar_env_a_db.py ruta/.env [entorno]")
    else:
        archivo = sys.argv[1]
        entorno = sys.argv[2] if len(sys.argv) > 2 else 'production'
        importar_env(archivo, entorno)
        importar_variables_entorno()