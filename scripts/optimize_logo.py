#!/usr/bin/env python3
"""
Script para optimizar el logo y crear diferentes tamaños
"""
import os
from PIL import Image, ImageEnhance
import sys

def optimize_logo(input_path, output_dir):
    """Optimiza el logo y crea diferentes tamaños"""
    
    # Crear directorio de salida si no existe
    os.makedirs(output_dir, exist_ok=True)
    
    try:
        # Abrir la imagen original
        with Image.open(input_path) as img:
            print(f"📁 Imagen original: {img.size} ({img.mode})")
            
            # Convertir a RGBA si no lo está
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            # Definir tamaños para diferentes usos
            sizes = {
                'logo_header': (40, 40),      # Header principal
                'logo_navbar': (28, 28),      # Barra de navegación
                'logo_mobile': (24, 24),      # Móvil
                'logo_favicon': (32, 32),     # Favicon
                'logo_large': (64, 64),       # Tamaño grande para modales
            }
            
            for name, size in sizes.items():
                # Redimensionar manteniendo proporción
                resized = img.resize(size, Image.Resampling.LANCZOS)
                
                # Mejorar nitidez
                enhancer = ImageEnhance.Sharpness(resized)
                sharpened = enhancer.enhance(1.2)
                
                # Guardar con optimización
                output_path = os.path.join(output_dir, f'{name}.png')
                sharpened.save(output_path, 'PNG', optimize=True, quality=95)
                
                print(f"✅ {name}: {size} - {os.path.getsize(output_path)} bytes")
            
            # Crear favicon.ico
            favicon_size = (32, 32)
            favicon = img.resize(favicon_size, Image.Resampling.LANCZOS)
            favicon_path = os.path.join(output_dir, 'favicon.ico')
            favicon.save(favicon_path, 'ICO', sizes=[(32, 32)])
            print(f"✅ favicon.ico: {favicon_size} - {os.path.getsize(favicon_path)} bytes")
            
    except Exception as e:
        print(f"❌ Error procesando imagen: {e}")
        return False
    
    return True

def main():
    # Rutas
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    input_path = os.path.join(base_dir, 'static', 'images', 'logo.png')
    output_dir = os.path.join(base_dir, 'static', 'images', 'optimized')
    
    if not os.path.exists(input_path):
        print(f"❌ No se encuentra el logo en: {input_path}")
        sys.exit(1)
    
    print("🎨 Optimizando logo...")
    print(f"📂 Entrada: {input_path}")
    print(f"📂 Salida: {output_dir}")
    print("-" * 50)
    
    if optimize_logo(input_path, output_dir):
        print("-" * 50)
        print("✅ Optimización completada exitosamente!")
        print("\n📋 Archivos creados:")
        print("  - logo_header.png (40x40) - Para el header")
        print("  - logo_navbar.png (28x28) - Para la navbar")
        print("  - logo_mobile.png (24x24) - Para móviles")
        print("  - logo_favicon.png (32x32) - Para favicon")
        print("  - logo_large.png (64x64) - Para modales")
        print("  - favicon.ico (32x32) - Favicon del sitio")
    else:
        print("❌ Error en la optimización")
        sys.exit(1)

if __name__ == "__main__":
    main()
