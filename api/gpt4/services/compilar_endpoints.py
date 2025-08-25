import os
import re
import sys


def leer_tsv(tsv_path: str):
    """
    Lee un TSV con encabezado: endpoint\tarchivo\tlinea\tframework
    Devuelve lista de endpoints.
    """
    endpoints = []
    if not os.path.isfile(tsv_path):
        return endpoints
    try:
        with open(tsv_path, 'r', encoding='utf-8', errors='ignore') as f:
            # omitir encabezado si coincide
            first = f.readline()
            if 'endpoint' not in first or '\t' not in first:
                # si no hay encabezado, procesar también la primera línea
                parts = first.strip().split('\t')
                if parts and parts[0]:
                    endpoints.append(parts[0])
            for linea in f:
                partes = linea.strip().split('\t')
                if not partes:
                    continue
                endpoint = partes[0].strip()
                if endpoint:
                    endpoints.append(endpoint)
    except Exception:
        pass
    return endpoints


def leer_tabla(tabla_path: str):
    """
    Lee las tablas alineadas *_tabla.txt y devuelve lista de endpoints (columna 1).
    Asume que las primeras dos líneas son encabezado + separador.
    """
    endpoints = []
    if not os.path.isfile(tabla_path):
        return endpoints
    patron = re.compile(r'^\s*(\S+)\s{2,}')
    try:
        with open(tabla_path, 'r', encoding='utf-8', errors='ignore') as f:
            lineas = f.readlines()
        for linea in lineas[2:]:  # saltar encabezado y separador
            m = patron.match(linea)
            if m:
                ep = m.group(1).strip()
                if ep:
                    endpoints.append(ep)
    except Exception:
        pass
    return endpoints


def compilar(reportes_dir: str, salida_txt: str, salida_tsv: str):
    """
    Compila endpoints únicos desde los 4 archivos estándar en reportes_dir y genera:
    - salida_txt: lista simple, uno por línea
    - salida_tsv: TSV compatible (endpoint, archivo, linea, framework)
    """
    tsv_encontrar = os.path.join(reportes_dir, 'endpoints_encontrar.tsv')
    tsv_escanear = os.path.join(reportes_dir, 'endpoints_escanear.tsv')
    tabla_encontrar = os.path.join(reportes_dir, 'endpoints_encontrar_tabla.txt_tabla.txt')
    tabla_escanear = os.path.join(reportes_dir, 'endpoints_escanear_tabla.txt_tabla.txt')
    # OpenAPI generados
    tsv_openapi = os.path.join(reportes_dir, 'endpoints_openapi.tsv')
    tabla_openapi = os.path.join(reportes_dir, 'endpoints_openapi_tabla.txt_tabla.txt')

    candidatos = []
    candidatos += leer_tsv(tsv_encontrar)
    candidatos += leer_tsv(tsv_escanear)
    candidatos += leer_tabla(tabla_encontrar)
    candidatos += leer_tabla(tabla_escanear)
    candidatos += leer_tsv(tsv_openapi)
    candidatos += leer_tabla(tabla_openapi)

    # Normalización ligera: quitar dobles // y espacios
    normalizados = []
    for ep in candidatos:
        e = ep.strip()
        e = re.sub(r'/+', '/', e)
        normalizados.append(e)

    unicos = sorted(set([e for e in normalizados if e]))

    # Asegurar carpeta destino
    os.makedirs(os.path.dirname(salida_txt), exist_ok=True)

    # Escribir lista simple
    with open(salida_txt, 'w', encoding='utf-8') as f:
        for ep in unicos:
            f.write(f"{ep}\n")

    # Escribir TSV compatible con descubrir_endpoints_ssl.py
    with open(salida_tsv, 'w', encoding='utf-8') as f:
        f.write('endpoint\tarchivo\tlinea\tframework\n')
        for ep in unicos:
            f.write(f"{ep}\tcompilado\t0\tcompilado\n")

    return unicos


def main():
    # Directorio por defecto de reportes
    reportes_dir = '/home/markmur88/endpoints/reportes'
    salida_txt = os.path.join(reportes_dir, 'endpoints_compilados.txt')
    salida_tsv = os.path.join(reportes_dir, 'endpoints_compilados.tsv')

    # Argumentos opcionales: reportes_dir [salida_txt] [salida_tsv]
    if len(sys.argv) > 1 and sys.argv[1].strip():
        reportes_dir = sys.argv[1]
    if len(sys.argv) > 2 and sys.argv[2].strip():
        salida_txt = sys.argv[2]
    if len(sys.argv) > 3 and sys.argv[3].strip():
        salida_tsv = sys.argv[3]

    unicos = compilar(reportes_dir, salida_txt, salida_tsv)
    print(f"Total únicos: {len(unicos)}")
    print(f"Lista: {salida_txt}")
    print(f"TSV:   {salida_tsv}")


if __name__ == '__main__':
    main()


