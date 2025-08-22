import os
import re
import sys

def encontrar_endpoints(directorio, archivo_salida):
    """
    Escanea archivos en busca de posibles endpoints de API y guarda resultados en archivo
    """
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
    ]
    
    # Extensiones de archivo a analizar
    extensiones_validas = ['.py', '.js', '.ts', '.java', '.php', '.go', '.rb', '.cs', '.cpp', '.c', '.h', '.hpp']
    
    for raiz, dirs, archivos in os.walk(directorio):
        # Ignorar directorios comunes que no contienen código
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__', 'venv', 'env', 'bin', 'obj']]
        
        for archivo in archivos:
            if not any(archivo.endswith(ext) for ext in extensiones_validas):
                continue
                
            ruta_completa = os.path.join(raiz, archivo)
            
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
    
    # Guardar resultados en archivo
    with open(archivo_salida, 'w', encoding='utf-8') as f:
        # Escribir encabezado
        f.write("endpoint\tarchivo\tlinea\tframework\n")
        
        # Escribir datos
        for endpoint, archivo, linea, framework in resultados:
            f.write(f"{endpoint}\t{archivo}\t{linea}\t{framework}\n")
    
    return resultados

def main():
    if len(sys.argv) < 3:
        print("Uso: python encontrar_endpoints.py <directorio> <archivo_salida.txt>")
        sys.exit(1)
        
    directorio = sys.argv[1]
    archivo_salida = sys.argv[2]
    
    if not os.path.isdir(directorio):
        print(f"Error: {directorio} no es un directorio válido")
        sys.exit(1)
        
    print(f"Escaneando directorio: {directorio}")
    resultados = encontrar_endpoints(directorio, archivo_salida)
    
    if not resultados:
        print("No se encontraron endpoints")
        return
        
    print(f"Resultados guardados en: {archivo_salida}")
    print(f"Total de endpoints encontrados: {len(resultados)}")

if __name__ == "__main__":
    main()