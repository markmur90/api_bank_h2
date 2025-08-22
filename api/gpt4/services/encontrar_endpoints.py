import os
import re
import sys

def encontrar_endpoints(directorio, archivo_salida, excluir_dirs=None):
    """
    Escanea recursivamente todos los archivos en busca de endpoints de API y guarda resultados en archivo
    """
    if excluir_dirs is None:
        # Directorios comunes a excluir por defecto
        excluir_dirs = ['.git', '.idea', '__pycache__', 'node_modules', 'venv', 'env', 'dist', 'build', 'target', 'bin', 'obj']
    
    resultados = []
    
    # Patrones para diferentes frameworks y lenguajes
    patrones = [
        # Python (Django, Flask, FastAPI)
        (r'@(?:app|router|blueprint)\.(?:get|post|put|delete|patch|route)\([\'"]([^\'"]+)[\'"]', 'Python (Flask/FastAPI)'),
        (r'path\([\'"]([^\'"]+)[\'"]', 'Python (Django)'),
        (r're_path\([\'"]([^\'"]+)[\'"]', 'Python (Django)'),
        (r'url\([\'"]([^\'"]+)[\'"]', 'Python (Django)'),
        
        # JavaScript/TypeScript (Express, Koa, etc.)
        (r'(?:app|router)\.(?:get|post|put|delete|patch|all|use)\([\'"]([^\'"]+)[\'"]', 'JavaScript/TypeScript (Express)'),
        (r'router\.(?:get|post|put|delete|patch|all)\([\'"]([^\'"]+)[\'"]', 'JavaScript/TypeScript (Router)'),
        
        # Java (Spring Boot, JAX-RS)
        (r'@(?:RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)\([\'"]([^\'"]+)[\'"]', 'Java (Spring)'),
        (r'@(?:Path)\([\'"]([^\'"]+)[\'"]', 'Java (JAX-RS)'),
        
        # PHP (Laravel, Symfony)
        (r'Route::(?:get|post|put|delete|patch|any)\([\'"]([^\'"]+)[\'"]', 'PHP (Laravel)'),
        (r'\$router->(?:get|post|put|delete|patch)\([\'"]([^\'"]+)[\'"]', 'PHP (Symfony)'),
        
        # Ruby on Rails
        (r'get\s+[\'"]([^\'"]+)[\'"]', 'Ruby (Rails)'),
        (r'post\s+[\'"]([^\'"]+)[\'"]', 'Ruby (Rails)'),
        
        # Go (Gin, Echo)
        (r'(?:r|router)\.(?:GET|POST|PUT|DELETE|PATCH)\([\'"]([^\'"]+)[\'"]', 'Go (Gin/Echo)'),
        
        # C# (ASP.NET Core)
        (r'\[(?:HttpGet|HttpPost|HttpPut|HttpDelete|HttpPatch)\([\'"]([^\'"]+)[\'"]', 'C# (ASP.NET)'),
        (r'Map(?:Get|Post|Put|Delete|Patch)\([\'"]([^\'"]+)[\'"]', 'C# (ASP.NET)'),
        
        # Rutas genéricas
        (r'ROUTE\([\'"]([^\'"]+)[\'"]', 'Ruta genérica'),
        (r'endpoint\s*=\s*[\'"]([^\'"]+)[\'"]', 'Configuración genérica'),
        # Rutas /gw/... genéricas en cualquier texto/código
        (r'(/gw(?:/[\w\.\-:]+)+/?)', 'Ruta /gw genérica'),
    ]

    # Compilar patrones para mejorar rendimiento
    patrones_compilados = [(re.compile(p), fw) for p, fw in patrones]
    
    # Extensiones de archivo a analizar
    extensiones_validas = ['.py', '.js', '.ts', '.java', '.php', '.go', '.rb', '.cs', '.cpp', '.c', '.h', '.hpp', '.html', '.xml', '.json', '.yml', '.yaml', '.md', '.txt']
    
    # Contadores para estadísticas
    total_archivos = 0
    archivos_procesados = 0
    archivos_con_endpoints = 0
    directorios_visitados = 0
    
    print(f"Iniciando escaneo recursivo de: {directorio}")
    print(f"Directorios excluidos: {', '.join(excluir_dirs)}")
    print("-" * 80)
    
    # Usamos os.walk con recursión explícita
    for raiz, dirs, archivos in os.walk(directorio):
        directorios_visitados += 1
        
        # Mostrar progreso cada 10 directorios
        if directorios_visitados % 10 == 0:
            print(f"Visitando directorio #{directorios_visitados}: {raiz}")
        
        # Filtrar directorios a excluir (creamos una nueva lista para no afectar la recursión)
        dirs_filtrados = []
        for d in dirs:
            if d not in excluir_dirs:
                dirs_filtrados.append(d)
            else:
                print(f"  Excluyendo directorio: {os.path.join(raiz, d)}")
        
        # Reemplazar la lista de directorios con la versión filtrada
        dirs[:] = dirs_filtrados
        
        # Mostrar subdirectorios que se visitarán
        if dirs:
            print(f"  Subdirectorios a visitar en {os.path.basename(raiz)}: {', '.join(dirs)}")
        
        for archivo in archivos:
            total_archivos += 1
            
            # Verificar extensión
            if not any(archivo.endswith(ext) for ext in extensiones_validas):
                continue
                
            ruta_completa = os.path.join(raiz, archivo)
            archivos_procesados += 1
            
            try:
                with open(ruta_completa, 'r', encoding='utf-8', errors='ignore') as f:
                    lineas = f.readlines()
                    
                    for num_linea, linea in enumerate(lineas, 1):
                        for patron_re, framework in patrones_compilados:
                            coincidencias = patron_re.finditer(linea)
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
    
    # Guardar resultados en archivo
    with open(archivo_salida, 'w', encoding='utf-8') as f:
        # Escribir encabezado
        f.write("endpoint\tarchivo\tlinea\tframework\n")
        
        # Escribir datos
        for endpoint, archivo, linea, framework in resultados:
            f.write(f"{endpoint}\t{archivo}\t{linea}\t{framework}\n")

    # Además, generar archivo de tabla alineada para lectura humana
    # Derivar nombre: <archivo_salida> -> <archivo_salida_sin_ext>_tabla.txt
    archivo_tabla = re.sub(r'(\.\w+)?$', '_tabla.txt', archivo_salida)

    if resultados:
        max_endpoint = max(len(r[0]) for r in resultados)
        max_archivo = max(len(r[1]) for r in resultados)
        max_linea   = max(len(str(r[2])) for r in resultados)

        formato = f"{{:<{max_endpoint+2}}} {{:<{max_archivo+2}}} {{:>{max_linea}}}"

        with open(archivo_tabla, 'w', encoding='utf-8') as tf:
            tf.write(formato.format("Endpoint", "Ruta archivo", "Línea archivo") + "\n")
            tf.write("-" * (max_endpoint + max_archivo + max_linea + 4) + "\n")
            for endpoint, archivo, linea, _framework in resultados:
                tf.write(formato.format(endpoint, archivo, str(linea)) + "\n")
    
    # Calcular estadísticas
    archivos_con_endpoints = len(set([r[1] for r in resultados]))
    
    print("\n" + "-" * 80)
    print(f"Escaneo completado:")
    print(f"  Directorios visitados: {directorios_visitados}")
    print(f"  Total de archivos encontrados: {total_archivos}")
    print(f"  Archivos procesados: {archivos_procesados}")
    print(f"  Archivos con endpoints: {archivos_con_endpoints}")
    print(f"  Total de endpoints encontrados: {len(resultados)}")
    print(f"  Resultados guardados en: {archivo_salida}")
    print(f"  Tabla legible guardada en: {archivo_tabla}")
    
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