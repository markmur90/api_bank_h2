#!/usr/bin/env python3
"""
Script de prueba para verificar la navegación entre páginas
"""
import os
import sys
import django

# Configurar Django con una configuración más simple
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.local')
os.environ.setdefault('DJANGO_ENV', 'local')

try:
    django.setup()
except Exception as e:
    print(f"Error configurando Django: {e}")
    print("Intentando con configuración alternativa...")
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base1')
    django.setup()

from django.test import Client
from django.urls import reverse

def test_navigation():
    """Prueba la navegación entre diferentes páginas"""
    client = Client()
    
    # URLs a probar
    urls_to_test = [
        'dashboard',
        'client',
        'terms_of_service',
        'privacy_policy',
        'notifications',
    ]
    
    print("🔍 Probando navegación entre páginas...")
    print("=" * 50)
    
    for url_name in urls_to_test:
        try:
            # Intentar acceder a la URL
            response = client.get(reverse(url_name))
            
            if response.status_code == 200:
                print(f"✅ {url_name}: OK (Status: {response.status_code})")
                
                # Verificar que el contenido sea diferente
                content_length = len(response.content)
                print(f"   📄 Longitud del contenido: {content_length} bytes")
                
                # Verificar headers de cache
                cache_control = response.get('Cache-Control', 'No definido')
                print(f"   🚫 Cache-Control: {cache_control}")
                
            elif response.status_code == 302:
                print(f"🔄 {url_name}: Redirección (Status: {response.status_code})")
                print(f"   ➡️  Redirige a: {response.url}")
                
            else:
                print(f"❌ {url_name}: Error (Status: {response.status_code})")
                
        except Exception as e:
            print(f"💥 {url_name}: Excepción - {str(e)}")
        
        print("-" * 30)
    
    print("🎯 Prueba completada!")

if __name__ == "__main__":
    test_navigation()
