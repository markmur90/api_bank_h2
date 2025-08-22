import sys
import os
import time
from urllib.parse import urljoin, urlparse
import re

# Importar la clase DeutscheBankClient del archivo existente
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from transfer_services import DeutscheBankClient

def leer_endpoints(archivo_entrada):
    """
    Lee el archivo de endpoints y devuelve una lista de tuplas
    """
    if not os.path.exists(archivo_entrada):
        print(f"Error: El archivo {archivo_entrada} no existe")
        return []
    
    resultados = []
    
    with open(archivo_entrada, 'r', encoding='utf-8') as f:
        # Saltar la primera línea (encabezado)
        next(f)
        
        for linea in f:
            # Dividir por tabulaciones
            partes = linea.strip().split('\t')
            if len(partes) == 4:
                endpoint, archivo, linea, framework = partes
                resultados.append((endpoint, archivo, int(linea), framework))
    
    return resultados

def probar_endpoints_con_ssl(client, endpoints, timeout=30):
    """
    Prueba cada endpoint usando la conexión SSL existente
    """
    resultados_prueba = []
    
    base_url = client.base_url
    print(f"Probando endpoints contra: {base_url}")
    print("-" * 80)
    
    # Reutilizar una sola sesión SSL para todas las pruebas
    session = client._create_session()
    for endpoint, archivo, linea, framework in endpoints:
        # Construir URL completa
        url = urljoin(base_url, endpoint.lstrip('/'))
        
        # Probar diferentes métodos HTTP
        metodos = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']
        
        for metodo in metodos:
            try:
                print(f"Probando {metodo} {url}...", end=' ')
                
                # Hacer la petición
                response = session.request(
                    metodo,
                    url,
                    timeout=timeout
                )
                
                # Si la respuesta es exitosa (2xx) o redirección (3xx)
                if 200 <= response.status_code < 400:
                    print(f"✅ {response.status_code}")
                    resultados_prueba.append({
                        'endpoint': endpoint,
                        'url': url,
                        'metodo': metodo,
                        'status': response.status_code,
                        'archivo': archivo,
                        'linea': linea,
                        'framework': framework
                    })
                    break  # No probar otros métodos para este endpoint
                else:
                    print(f"❌ {response.status_code}")
                
                # Pequeña pausa para no sobrecargar el servidor
                time.sleep(0.1)
                
            except Exception as e:
                print(f"❌ Error: {str(e)}")
                break
    
    return resultados_prueba

def mostrar_resultados(resultados):
    """
    Muestra los resultados de las pruebas en formato de tabla
    """
    if not resultados:
        print("\nNo se encontraron endpoints accesibles")
        return
    
    # Ordenar por endpoint
    resultados.sort(key=lambda x: x['endpoint'])
    
    # Calcular anchos de columna
    max_endpoint = max(len(r['endpoint']) for r in resultados)
    max_metodo = 5
    max_status = 6
    max_archivo = max(len(os.path.basename(r['archivo'])) for r in resultados)
    max_framework = max(len(r['framework']) for r in resultados)
    
    # Formato de la tabla
    formato = f"{{:<{max_endpoint+2}}} {{:<{max_metodo+2}}} {{:<{max_status+2}}} {{:<{max_archivo+2}}} {{:<{max_framework+2}}}"
    
    # Encabezado
    print("\nEndpoints accesibles encontrados:")
    print(formato.format("Endpoint", "Método", "Status", "Archivo", "Framework"))
    print("-" * (max_endpoint + max_metodo + max_status + max_archivo + max_framework + 10))
    
    # Datos
    for r in resultados:
        nombre_archivo = os.path.basename(r['archivo'])
        print(formato.format(
            r['endpoint'],
            r['metodo'],
            str(r['status']),
            nombre_archivo,
            r['framework']
        ))
    
    print(f"\nTotal de endpoints accesibles: {len(resultados)}")

def main():
    # Soporte de uso sin argumentos: usar archivo compilado por defecto
    archivo_por_defecto = "/home/markmur88/endpoints/reportes/endpoints_compilados.tsv"
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        archivo_entrada = archivo_por_defecto
        print(f"Usando archivo por defecto: {archivo_entrada}")
    else:
        archivo_entrada = sys.argv[1]
    
    # Si no existe, intentar compilar automáticamente a partir de los reportes
    if not os.path.exists(archivo_entrada):
        try:
            print("Archivo no encontrado. Generando lista compilada desde reportes...")
            # Importación local para evitar dependencias circulares
            from compilar_endpoints import compilar
            reportes_dir = "/home/markmur88/endpoints/reportes"
            salida_txt = os.path.join(reportes_dir, 'endpoints_compilados.txt')
            salida_tsv = os.path.join(reportes_dir, 'endpoints_compilados.tsv')
            compilar(reportes_dir, salida_txt, salida_tsv)
        except Exception as e:
            print(f"No se pudo generar la lista compilada automáticamente: {e}")
    
    
    print(f"Leyendo endpoints desde: {archivo_entrada}")
    endpoints = leer_endpoints(archivo_entrada)
    
    if not endpoints:
        print("No se encontraron endpoints en el archivo")
        return
    
    print(f"Se encontraron {len(endpoints)} endpoints en el archivo")
    
    # Crear cliente SSL usando la clase existente
    try:
        print("Iniciando cliente SSL...")
        client = DeutscheBankClient()
        
        # Probar la conexión SSL primero
        print("Probando conexión SSL...")
        if not client.test_connection():
            print("❌ Error: No se pudo establecer conexión SSL con el servidor")
            return
        
        print("✅ Conexión SSL establecida correctamente")
    except Exception as e:
        print(f"❌ Error al crear el cliente SSL: {str(e)}")
        return
    
    # Probar los endpoints
    resultados = probar_endpoints_con_ssl(client, endpoints)
    
    # Mostrar resultados
    mostrar_resultados(resultados)

if __name__ == "__main__":
    main()