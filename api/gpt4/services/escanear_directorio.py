import os
import re
import sys

def escanear_directorio(directorio, resultados, patrones, extensiones_validas, excluir_dirs):
    """
    Función recursiva para escanear directorios
    """
    try:
        # Listar contenido del directorio
        contenido = os.listdir(directorio)
    except PermissionError:
        print(f"Permiso denegado para acceder a: {directorio}")
        return
    except Exception as e:
        print(f"Error al acceder a {directorio}: {str(e)}")
        return
    
    print(f"Escaneando directorio: {directorio}")
    
    for item in contenido:
        ruta_completa = os.path.join(directorio, item)
        
        # Si es un directorio
        if os.path.isdir(ruta_completa):
            # Verificar si está en la lista de exclusión
            if item in excluir_dirs:
                print(f"  Excluyendo directorio: {ruta_completa}")
                continue
            
            # Llamada recursiva
            escanear_directorio(ruta_completa, resultados, patrones, extensiones_validas, excluir_dirs)
        
        # Si es un archivo
        elif os.path.isfile(ruta_completa):
            # Verificar extensión
            if not any(item.endswith(ext) for ext in extensiones_validas):
                continue
            
            try:
                with open(ruta_completa, 'r', encoding='utf-8', errors='ignore') as f:
                    lineas = f.readlines()
                    
                    for num_linea, linea in enumerate(lineas, 1):
                        for patron, framework in patrones:
                            coincidencias = re.finditer(patron, linea)
                            for coincidencia in coincidencias:
                                endpoint = coincidencia.group(1)
                                
                                # Limpiar el endpoint
                                if endpoint.startswith('^'):
                                    endpoint = endpoint[1:]
                                if endpoint.endswith('$'):
                                    endpoint = endpoint[:-1]
                                    
                                resultados.append((endpoint, ruta_completa, num_linea, framework))
                                
            except Exception as e:
                print(f"Error al procesar {ruta_completa}: {str(e)}")

def encontrar_endpoints(directorio, archivo_salida, excluir_dirs=None):
    """
    Escanea recursivamente todos los archivos en busca de endpoints de API
    """
    if excluir_dirs is None:
        excluir_dirs = ['.git', '.idea', '__pycache__', 'node_modules', 'venv', 'env', 'dist', 'build', 'target', 'bin', 'obj']
    
    resultados = []
    
    # Patrones para diferentes frameworks y lenguajes
    patrones = [
        # ... (mismos patrones que antes)
    ]
    
    # Extensiones de archivo a analizar
    extensiones_validas = ['.py', '.js', '.ts', '.java', '.php', '.go', '.rb', '.cs', '.cpp', '.c', '.h', '.hpp', '.html', '.xml', '.json', '.yml', '.md','.txt','.yaml']
    
    print(f"Iniciando escaneo recursivo de: {directorio}")
    print(f"Directorios excluidos: {', '.join(excluir_dirs)}")
    print("-" * 80)
    
    # Iniciar escaneo recursivo
    escanear_directorio(directorio, resultados, patrones, extensiones_validas, excluir_dirs)
    
    # Guardar resultados en archivo
    with open(archivo_salida, 'w', encoding='utf-8') as f:
        # Escribir encabezado
        f.write("endpoint\tarchivo\tlinea\tframework\n")
        
        # Escribir datos
        for endpoint, archivo, linea, framework in resultados:
            f.write(f"{endpoint}\t{archivo}\t{linea}\t{framework}\n")
    
    # Calcular estadísticas
    archivos_con_endpoints = len(set([r[1] for r in resultados]))
    
    print("\n" + "-" * 80)
    print(f"Escaneo completado:")
    print(f"  Total de endpoints encontrados: {len(resultados)}")
    print(f"  Archivos con endpoints: {archivos_con_endpoints}")
    print(f"  Resultados guardados en: {archivo_salida}")
    
    return resultados

def main():
    if len(sys.argv) < 3:
        print("Uso: python encontrar_endpoints.py <directorio> <archivo_salida.txt> [directorios_a_excluir]")
        print("Ejemplo: python encontrar_endpoints.py /ruta/a/tu/proyecto endpoints.txt")
        print("Ejemplo con exclusión: python encontrar_endpoints.py /ruta/a/tu/proyecto endpoints.txt '.git,node_modules,venv'")
        sys.exit(1)
        
    directorio = sys.argv[1]
    archivo_salida = sys.argv[2]
    
    # Procesar directorios a excluir si se proporcionan
    excluir_dirs = None
    if len(sys.argv) > 3:
        excluir_dirs = sys.argv[3].split(',')
        print(f"Excluyendo directorios: {', '.join(excluir_dirs)}")
    
    if not os.path.isdir(directorio):
        print(f"Error: {directorio} no es un directorio válido")
        sys.exit(1)
        
    resultados = encontrar_endpoints(directorio, archivo_salida, excluir_dirs)
    
    if not resultados:
        print("No se encontraron endpoints")
        return

if __name__ == "__main__":
    main()