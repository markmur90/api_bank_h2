import os
import re
import sys
import subprocess

def _es_archivo_texto_procesable(nombre_archivo: str, extensiones_validas):
    """
    True si el archivo debe procesarse: extensión válida o sin extensión.
    """
    base, ext = os.path.splitext(nombre_archivo)
    if ext:
        return any(nombre_archivo.endswith(v) for v in extensiones_validas)
    return True


def _parsear_tree_txt(archivo_tree: str):
    rutas = []
    try:
        with open(archivo_tree, 'r', encoding='utf-8', errors='ignore') as f:
            lineas = [l.rstrip('\n') for l in f]
    except Exception:
        return rutas

    if not lineas:
        return rutas

    # Lista plana de rutas absolutas
    for linea in lineas:
        s = linea.strip()
        if s.startswith('/') and os.path.isfile(s):
            rutas.append(s)
    if rutas:
        return rutas

    root_dir = lineas[0].strip()
    if not os.path.isabs(root_dir) or not os.path.isdir(root_dir):
        return rutas

    ramas = []
    for idx in range(1, len(lineas)):
        linea = lineas[idx]
        m = re.search(r'^[\s│]*[├└]──\s+(.*)$', linea)
        if not m:
            continue
        prefijo = linea[:m.start(0)]
        nombre = m.group(1).strip()
        depth = max(0, len(re.sub(r'[^\s]', ' ', prefijo)) // 4)
        ramas.append((idx, depth, nombre))

    pila = []
    for i, (idx, depth, nombre) in enumerate(ramas):
        next_depth = ramas[i + 1][1] if i + 1 < len(ramas) else 0
        if depth < len(pila):
            pila = pila[:depth]
        elif depth > len(pila):
            pila.extend([None] * (depth - len(pila)))

        es_directorio = next_depth > depth
        if es_directorio:
            if depth == len(pila):
                pila.append(nombre)
            else:
                pila[depth] = nombre
            continue

        partes = [p for p in pila if p]
        ruta_abs = os.path.join(root_dir, *partes, nombre) if partes else os.path.join(root_dir, nombre)
        if os.path.isfile(ruta_abs):
            rutas.append(ruta_abs)

    return rutas


def escanear_directorio(directorio, resultados, patrones, extensiones_validas, excluir_dirs, archivo_tree_txt=None):
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
            # Verificar archivo procesable (ext válida o sin extensión)
            if not _es_archivo_texto_procesable(item, extensiones_validas):
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

def encontrar_endpoints(directorio, archivo_salida, excluir_dirs=None, archivo_tree_txt=None):
    """
    Escanea recursivamente todos los archivos en busca de endpoints de API
    """
    if excluir_dirs is None:
        excluir_dirs = ['.git', '.idea', '__pycache__', 'node_modules', 'venv', 'env', 'dist', 'build', 'target', 'bin', 'obj']
    
    resultados = []
    
    patrones = [
        # Python (Django, Flask, FastAPI)
        (r'@(?:app|router|blueprint)\.(?:get|post|put|delete|patch|route)\([\'\"]([^\'\"]+)[\'\"]', 'Python (Flask/FastAPI)'),
        (r'path\([\'\"]([^\'\"]+)[\'\"]', 'Python (Django)'),
        (r're_path\([\'\"]([^\'\"]+)[\'\"]', 'Python (Django)'),
        (r'url\([\'\"]([^\'\"]+)[\'\"]', 'Python (Django)'),

        # JavaScript/TypeScript (Express, Koa, etc.)
        (r'(?:app|router)\.(?:get|post|put|delete|patch|all|use)\([\'\"]([^\'\"]+)[\'\"]', 'JavaScript/TypeScript (Express)'),
        (r'router\.(?:get|post|put|delete|patch|all)\([\'\"]([^\'\"]+)[\'\"]', 'JavaScript/TypeScript (Router)'),

        # Java (Spring Boot, JAX-RS)
        (r'@(?:RequestMapping|GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping)\([\'\"]([^\'\"]+)[\'\"]', 'Java (Spring)'),
        (r'@(?:Path)\([\'\"]([^\'\"]+)[\'\"]', 'Java (JAX-RS)'),

        # PHP (Laravel, Symfony)
        (r'Route::(?:get|post|put|delete|patch|any)\([\'\"]([^\'\"]+)[\'\"]', 'PHP (Laravel)'),
        (r'\$router->(?:get|post|put|delete|patch)\([\'\"]([^\'\"]+)[\'\"]', 'PHP (Symfony)'),

        # Ruby on Rails
        (r'get\s+[\'\"]([^\'\"]+)[\'\"]', 'Ruby (Rails)'),
        (r'post\s+[\'\"]([^\'\"]+)[\'\"]', 'Ruby (Rails)'),

        # Go (Gin, Echo)
        (r'(?:r|router)\.(?:GET|POST|PUT|DELETE|PATCH)\([\'\"]([^\'\"]+)[\'\"]', 'Go (Gin/Echo)'),

        # C# (ASP.NET Core)
        (r'\[(?:HttpGet|HttpPost|HttpPut|HttpDelete|HttpPatch)\([\'\"]([^\'\"]+)[\'\"]', 'C# (ASP.NET)'),
        (r'Map(?:Get|Post|Put|Delete|Patch)\([\'\"]([^\'\"]+)[\'\"]', 'C# (ASP.NET)'),

        # Rutas genéricas
        (r'ROUTE\([\'\"]([^\'\"]+)[\'\"]', 'Ruta genérica'),
        (r'endpoint\s*=\s*[\'\"]([^\'\"]+)[\'\"]', 'Configuración genérica'),
        # Rutas /gw/... genéricas en cualquier texto/código
        (r'(/gw(?:/[\w\.\-:]+)+/?)', 'Ruta /gw genérica'),
    ]
    
    # Extensiones de archivo a analizar (agregamos .sh)
    extensiones_validas = ['.py', '.js', '.ts', '.java', '.php', '.go', '.rb', '.cs', '.cpp', '.c', '.h', '.hpp', '.html', '.xml', '.json', '.yml', '.md','.txt','.yaml', '.sh']
    
    print(f"Iniciando escaneo recursivo de: {directorio}")
    print(f"Directorios excluidos: {', '.join(excluir_dirs)}")
    print("-" * 80)
    
    # Si se proporciona lista desde tree, procesar solo esos archivos
    lista_desde_tree = []
    if archivo_tree_txt:
        lista_desde_tree = _parsear_tree_txt(archivo_tree_txt)

    if lista_desde_tree:
        for ruta_completa in lista_desde_tree:
            try:
                with open(ruta_completa, 'r', encoding='utf-8', errors='ignore') as f:
                    lineas = f.readlines()
                    for num_linea, linea in enumerate(lineas, 1):
                        for patron, framework in patrones:
                            for coincidencia in re.finditer(patron, linea):
                                endpoint = coincidencia.group(1)
                                if endpoint.startswith('^'):
                                    endpoint = endpoint[1:]
                                if endpoint.endswith('$'):
                                    endpoint = endpoint[:-1]
                                resultados.append((endpoint, ruta_completa, num_linea, framework))
            except Exception as e:
                print(f"Error al procesar {ruta_completa}: {str(e)}")
    else:
        # Iniciar escaneo recursivo normal
        escanear_directorio(directorio, resultados, patrones, extensiones_validas, excluir_dirs)
    
    # Guardar resultados en archivo
    with open(archivo_salida, 'w', encoding='utf-8') as f:
        # Escribir encabezado
        f.write("endpoint\tarchivo\tlinea\tframework\n")
        
        # Escribir datos
        for endpoint, archivo, linea, framework in resultados:
            f.write(f"{endpoint}\t{archivo}\t{linea}\t{framework}\n")

    # Además, generar archivo de tabla alineada para lectura humana
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
    print(f"  Total de endpoints encontrados: {len(resultados)}")
    print(f"  Archivos con endpoints: {archivos_con_endpoints}")
    print(f"  Resultados guardados en: {archivo_salida}")
    print(f"  Tabla legible guardada en: {archivo_tabla}")
    
    return resultados

def main():
    if len(sys.argv) < 2:
        print("Uso: python escanear_directorio.py <directorio> [archivo_salida.tsv] [directorios_a_excluir] [archivo_tree_txt]")
        print("Ejemplo mínimo: python escanear_directorio.py /ruta/a/tu/proyecto")
        print("Ejemplo con salida: python escanear_directorio.py /ruta/a/tu/proyecto /home/user/endpoints_escanear.tsv")
        print("Ejemplo con exclusión: python escanear_directorio.py /ruta/a/tu/proyecto '' '.git,node_modules,venv'")
        print("Ejemplo usando lista de tree: python escanear_directorio.py /ruta/root '' '' /ruta/a/tree.txt")
        sys.exit(1)
        
    directorio = sys.argv[1]
    # Salida por defecto en endpoints/reportes
    salida_por_defecto = "/home/markmur88/endpoints/reportes/endpoints_escanear.tsv"
    if len(sys.argv) > 2 and sys.argv[2].strip():
        archivo_salida = sys.argv[2]
    else:
        try:
            os.makedirs("/home/markmur88/endpoints/reportes", exist_ok=True)
        except Exception:
            pass
        archivo_salida = salida_por_defecto
    
    # Procesar directorios a excluir si se proporcionan
    excluir_dirs = None
    if len(sys.argv) > 3 and sys.argv[3].strip():
        excluir_dirs = sys.argv[3].split(',')
        print(f"Excluyendo directorios: {', '.join(excluir_dirs)}")
    archivo_tree_txt = None
    if len(sys.argv) > 4 and sys.argv[4].strip():
        archivo_tree_txt = sys.argv[4]
        print(f"Usando lista de archivos desde: {archivo_tree_txt}")
    else:
        # Generar automáticamente la lista con find en endpoints/tree
        base = os.path.basename(os.path.abspath(directorio)) or "root"
        try:
            os.makedirs("/home/markmur88/endpoints/tree", exist_ok=True)
        except Exception:
            pass
        archivo_tree_txt = f"/home/markmur88/endpoints/tree/tree__{base}.txt"
        print(f"Generando lista de archivos con find en: {archivo_tree_txt}")
        try:
            with open(archivo_tree_txt, 'w', encoding='utf-8', errors='ignore') as out:
                subprocess.run(['find', directorio, '-type', 'f'], stdout=out, stderr=subprocess.DEVNULL, check=False)
        except Exception as e:
            print(f"No se pudo generar la lista con find: {e}")
    
    if not os.path.isdir(directorio):
        print(f"Error: {directorio} no es un directorio válido")
        sys.exit(1)
        
    resultados = encontrar_endpoints(directorio, archivo_salida, excluir_dirs, archivo_tree_txt)
    
    if not resultados:
        print("No se encontraron endpoints")
        return

if __name__ == "__main__":
    main()