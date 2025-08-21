#!/usr/bin/env python3
"""
Script de diagnóstico para el sistema de certificados Deutsche Bank
"""

import os
import sys
import django
from pathlib import Path

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.production')
django.setup()

from django.conf import settings
from api.gpt4.services.transfer_services import verificar_certificados_disponibles, DeutscheBankClient
from api.configuraciones_api.helpers import get_conf

def diagnostico_certificados():
    print("🔍 DIAGNÓSTICO DEL SISTEMA DE CERTIFICADOS DEUTSCHE BANK")
    print("=" * 60)
    
    # 1. Verificar BASE_DIR
    print(f"📁 BASE_DIR: {settings.BASE_DIR}")
    
    # 2. Verificar rutas de certificados
    base_path = os.path.join(settings.BASE_DIR, 'deutsche_bank_certs')
    cert_path = os.path.join(base_path, 'deutsche_bank_certificate.pem')
    key_path = os.path.join(base_path, 'deutsche_bank_private_key.pem')
    p12_path = os.path.join(base_path, 'deutsche_bank.p12')
    
    print(f"�� Ruta base certificados: {base_path}")
    print(f"�� Certificado: {cert_path}")
    print(f"🔑 Clave privada: {key_path}")
    print(f"📦 Bundle P12: {p12_path}")
    
    # 3. Verificar existencia de archivos
    print("\n📋 VERIFICACIÓN DE ARCHIVOS:")
    archivos = [
        (cert_path, "Certificado"),
        (key_path, "Clave privada"),
        (p12_path, "Bundle P12")
    ]
    
    for archivo, nombre in archivos:
        if os.path.exists(archivo):
            size = os.path.getsize(archivo)
            print(f"✅ {nombre}: {archivo} ({size} bytes)")
        else:
            print(f"❌ {nombre}: {archivo} (NO ENCONTRADO)")
    
    # 4. Verificar función de verificación
    print("\n�� VERIFICACIÓN DEL SISTEMA:")
    try:
        disponibles, mensaje = verificar_certificados_disponibles()
        if disponibles:
            print(f"✅ {mensaje}")
        else:
            print(f"❌ {mensaje}")
    except Exception as e:
        print(f"❌ Error en verificación: {e}")
    
    # 5. Verificar configuración
    print("\n⚙️ CONFIGURACIÓN:")
    config_vars = [
        "BANK_USER", "BANK_PASS", "TOKEN_PATH", "AUTH_PATH", "SEND_PATH"
    ]
    
    for var in config_vars:
        valor = get_conf(var)
        if valor:
            print(f"✅ {var}: {valor}")
        else:
            print(f"❌ {var}: NO CONFIGURADO")
    
    # 6. Probar cliente
    print("\n�� PRUEBA DEL CLIENTE:")
    try:
        client = DeutscheBankClient()
        print("✅ Cliente Deutsche Bank creado exitosamente")
        print(f"   URL base: {client.base_url}")
        print(f"   Certificado: {client.cert_path}")
        print(f"   Clave: {client.key_path}")
    except Exception as e:
        print(f"❌ Error creando cliente: {e}")

if __name__ == "__main__":
    diagnostico_certificados()