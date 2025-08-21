#!/usr/bin/env python3
"""
Script de diagnóstico simple para el sistema de certificados Deutsche Bank
(No requiere conexión a base de datos)
"""

import os
import sys
from pathlib import Path

def diagnostico_certificados_simple():
    print("�� DIAGNÓSTICO SIMPLE DEL SISTEMA DE CERTIFICADOS DEUTSCHE BANK")
    print("=" * 65)
    
    # 1. Verificar BASE_DIR
    base_dir = Path(__file__).resolve().parent
    print(f"📁 BASE_DIR: {base_dir}")
    
    # 2. Verificar rutas de certificados
    base_path = base_dir / 'deutsche_bank_certs'
    cert_path = base_path / 'deutsche_bank_certificate.pem'
    key_path = base_path / 'deutsche_bank_private_key.pem'
    p12_path = base_path / 'deutsche_bank.p12'
    
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
    
    todos_existen = True
    for archivo, nombre in archivos:
        if archivo.exists():
            size = archivo.stat().st_size
            print(f"✅ {nombre}: {archivo} ({size} bytes)")
        else:
            print(f"❌ {nombre}: {archivo} (NO ENCONTRADO)")
            todos_existen = False
    
    # 4. Verificar permisos
    print("\n🔒 VERIFICACIÓN DE PERMISOS:")
    if key_path.exists():
        perms = oct(key_path.stat().st_mode)[-3:]
        if perms == '600':
            print(f"✅ Permisos de clave privada correctos: {perms}")
        else:
            print(f"⚠️ Permisos de clave privada: {perms} (recomendado: 600)")
    
    # 5. Verificar configuración del entorno
    print("\n⚙️ CONFIGURACIÓN DEL ENTORNO:")
    env_file = base_dir / '.env.production'
    if env_file.exists():
        print(f"✅ Archivo de configuración encontrado: {env_file}")
        
        # Leer variables clave del archivo .env
        with open(env_file, 'r') as f:
            content = f.read()
            
        variables_clave = [
            'BANK_USER', 'BANK_PASS', 'TOKEN_PATH', 'AUTH_PATH', 'SEND_PATH'
        ]
        
        for var in variables_clave:
            if f'{var}=' in content:
                print(f"✅ {var}: Configurado")
            else:
                print(f"❌ {var}: NO CONFIGURADO")
    else:
        print(f"❌ Archivo de configuración no encontrado: {env_file}")
    
    # 6. Resumen
    print("\n📊 RESUMEN:")
    if todos_existen:
        print("✅ Todos los certificados están en su lugar")
        print("✅ El sistema debería usar certificados SSL")
        print("✅ NO deberías obtener errores SSL")
    else:
        print("❌ Faltan algunos certificados")
        print("❌ El sistema usará método original (puede dar error SSL)")
    
    # 7. Próximos pasos
    print("\n�� PRÓXIMOS PASOS:")
    if todos_existen:
        print("1. Ejecutar el servidor Django")
        print("2. Probar una transferencia")
        print("3. Verificar logs para confirmar uso de certificados")
    else:
        print("1. Generar certificados faltantes")
        print("2. Verificar rutas y permisos")
        print("3. Ejecutar diagnóstico nuevamente")

if __name__ == "__main__":
    diagnostico_certificados_simple()