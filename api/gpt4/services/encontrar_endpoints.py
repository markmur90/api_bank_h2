import os
import re
import sys
import subprocess

def _es_archivo_texto_procesable(nombre_archivo: str, extensiones_validas):
    """
    Devuelve True si el archivo debe procesarse:
    - Tiene una extensión en la lista válida, o
    - No tiene extensión (archivos tipo script o texto sin extensión)
    """
    # Considerar archivos sin extensión
    base, ext = os.path.splitext(nombre_archivo)
    if ext:
        return any(nombre_archivo.endswith(v) for v in extensiones_validas)
    # Sin extensión: incluir
    return True


def _parsear_tree_txt(archivo_tree: str):
    """
    Parsea un archivo de salida de `tree` o una lista plana de rutas y
    devuelve una lista de rutas absolutas de archivos.

    Reglas:
    - Si una línea comienza con '/', se trata como ruta absoluta directa.
    - Si parece salida de tree:
      * La primera línea es el directorio raíz
      * Para cada línea con ├── o └── se determina el nivel por longitud del prefijo
      * Si la siguiente línea tiene mayor nivel, es un directorio; si no, es archivo
    """
    rutas = []
    try:
        with open(archivo_tree, 'r', encoding='utf-8', errors='ignore') as f:
            lineas = [l.rstrip('\n') for l in f]
    except Exception:
        return rutas

    if not lineas:
        return rutas

    # Caso lista plana: cualquier línea absoluta existente
    for linea in lineas:
        s = linea.strip()
        if s.startswith('/') and os.path.isfile(s):
            rutas.append(s)
    if rutas:
        return rutas

    # Intentar parseo de tree
    root_dir = lineas[0].strip()
    if not os.path.isabs(root_dir) or not os.path.isdir(root_dir):
        # No parece tree válido
        return rutas

    # Preprocesar: obtener tripletas (depth, name) para líneas con ramas
    ramas = []
    for idx in range(1, len(lineas)):
        linea = lineas[idx]
        # buscar rama ├── o └── (puede venir con espacios o │)
        m = re.search(r'^[\s│]*[├└]──\s+(.*)$', linea)
        if not m:
            continue
        prefijo = linea[:m.start(0)]
        nombre = m.group(1).strip()
        # depth aproximado por ancho del prefijo en grupos de 4
        depth = max(0, len(re.sub(r'[^\s]', ' ', prefijo)) // 4)
        ramas.append((idx, depth, nombre))

    # Reconstruir rutas usando la comparación de profundidad con la siguiente línea
    pila = []  # nombres de directorios relativos a root
    for i, (idx, depth, nombre) in enumerate(ramas):
        next_depth = ramas[i + 1][1] if i + 1 < len(ramas) else 0
        # Ajustar pila al nivel actual
        if depth < len(pila):
            pila = pila[:depth]
        elif depth > len(pila):
            # Si aumenta sin haber agregado directorio, asumimos ya ajustado por línea previa
            pila.extend([None] * (depth - len(pila)))

        # Directorio si la próxima línea es más profunda
        es_directorio = next_depth > depth
        if es_directorio:
            # Registrar este nombre como directorio en la profundidad actual
            if depth == len(pila):
                pila.append(nombre)
            else:
                pila[depth] = nombre
            continue

        # Es archivo (hoja)
        partes = [p for p in pila if p]
        ruta_abs = os.path.join(root_dir, *partes, nombre) if partes else os.path.join(root_dir, nombre)
        if os.path.isfile(ruta_abs):
            rutas.append(ruta_abs)

    return rutas


def encontrar_endpoints(directorio, archivo_salida, excluir_dirs=None, archivo_tree_txt=None):
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
    
    # Extensiones de archivo a analizar (agregamos .sh)
    extensiones_validas = ['.py', '.js', '.ts', '.java', '.php', '.go', '.rb', '.cs', '.cpp', '.c', '.h', '.hpp', '.html', '.xml', '.json', '.yml', '.yaml', '.md', '.txt', '.sh']
    
    # Contadores para estadísticas
    total_archivos = 0
    archivos_procesados = 0
    archivos_con_endpoints = 0
    directorios_visitados = 0
    
    print(f"Iniciando escaneo recursivo de: {directorio}")
    print(f"Directorios excluidos: {', '.join(excluir_dirs)}")
    print("-" * 80)
    
    # Si se proporciona un archivo con listado (tree o lista plana), procesar únicamente esos archivos
    lista_desde_tree = []
    if archivo_tree_txt:
        lista_desde_tree = _parsear_tree_txt(archivo_tree_txt)

    if lista_desde_tree:
        for ruta_completa in lista_desde_tree:
            total_archivos += 1
            nombre_archivo = os.path.basename(ruta_completa)
            if not _es_archivo_texto_procesable(nombre_archivo, extensiones_validas):
                continue
            try:
                with open(ruta_completa, 'r', encoding='utf-8', errors='ignore') as f:
                    archivos_procesados += 1
                    for num_linea, linea in enumerate(f, 1):
                        for patron_re, framework in patrones_compilados:
                            for coincidencia in patron_re.finditer(linea):
                                endpoint = coincidencia.group(1)
                                if endpoint.startswith('^'):
                                    endpoint = endpoint[1:]
                                if endpoint.endswith('$'):
                                    endpoint = endpoint[:-1]
                                resultados.append((endpoint, ruta_completa, num_linea, framework))
            except Exception as e:
                print(f"Error al procesar {ruta_completa}: {str(e)}")
    else:
        # Usamos os.walk con recursión explícita
        for raiz, dirs, archivos in os.walk(directorio):
            directorios_visitados += 1
            if directorios_visitados % 10 == 0:
                print(f"Visitando directorio #{directorios_visitados}: {raiz}")
            # Filtrar directorios a excluir (creamos una nueva lista para no afectar la recursión)
            dirs_filtrados = []
            for d in dirs:
                if d not in excluir_dirs:
                    dirs_filtrados.append(d)
                else:
                    print(f"  Excluyendo directorio: {os.path.join(raiz, d)}")
            dirs[:] = dirs_filtrados
            if dirs:
                print(f"  Subdirectorios a visitar en {os.path.basename(raiz)}: {', '.join(dirs)}")
            for archivo in archivos:
                total_archivos += 1
                if not _es_archivo_texto_procesable(archivo, extensiones_validas):
                    continue
                ruta_completa = os.path.join(raiz, archivo)
                try:
                    with open(ruta_completa, 'r', encoding='utf-8', errors='ignore') as f:
                        archivos_procesados += 1
                        for num_linea, linea in enumerate(f, 1):
                            for patron_re, framework in patrones_compilados:
                                for coincidencia in patron_re.finditer(linea):
                                    endpoint = coincidencia.group(1)
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
    if len(sys.argv) < 2:
        print("Uso: python encontrar_endpoints.py <directorio> [archivo_salida.tsv] [directorios_a_excluir] [archivo_tree_txt]")
        print("Ejemplo mínimo: python encontrar_endpoints.py /ruta/a/tu/proyecto")
        print("Ejemplo con salida: python encontrar_endpoints.py /ruta/a/tu/proyecto /home/user/endpoints_encontrar.tsv")
        print("Ejemplo con exclusión: python encontrar_endpoints.py /ruta/a/tu/proyecto '' '.git,node_modules,venv'")
        print("Ejemplo usando lista de tree: python encontrar_endpoints.py /ruta/root '' '' /ruta/a/tree.txt")
        sys.exit(1)
        
    directorio = sys.argv[1]
    # Salida por defecto en endpoints/reportes
    salida_por_defecto = "/home/markmur88/endpoints/reportes/endpoints_encontrar.tsv"
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