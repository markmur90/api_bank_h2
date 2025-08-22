import os
import sys
import json
from urllib.parse import urlparse


HTTP_METHODS = {"get", "post", "put", "delete", "patch", "head", "options"}


def join_paths(a: str, b: str) -> str:
    a = a or "/"
    b = b or "/"
    if not a.startswith("/"):
        a = "/" + a
    if a.endswith("/"):
        a = a[:-1]
    if not b.startswith("/"):
        b = "/" + b
    return (a + b).replace("//", "/")


def load_openapi(path: str) -> dict:
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return json.load(f)


def extract_endpoints_from_openapi(doc: dict) -> list:
    endpoints = []
    # Determinar base_path desde servers (si existe)
    base_path = "/"
    servers = doc.get("servers", [])
    for s in servers:
        url = s.get("url", "")
        try:
            p = urlparse(url)
            if p.path:
                base_path = p.path
                break
        except Exception:
            continue

    paths = doc.get("paths", {})
    for rel_path, item in paths.items():
        # Cuando la ruta en OpenAPI es " / " unir correctamente
        full_path = join_paths(base_path, rel_path)
        methods = [m for m in item.keys() if m.lower() in HTTP_METHODS]
        if not methods:
            # Aun si no hay métodos, registrar la ruta base
            endpoints.append((full_path, None))
        else:
            for m in methods:
                endpoints.append((full_path, m.upper()))
    return endpoints


def write_reports(endpoints: list, source_path: str, out_dir: str):
    os.makedirs(out_dir, exist_ok=True)
    tsv_path = os.path.join(out_dir, "endpoints_openapi.tsv")
    tabla_path = os.path.join(out_dir, "endpoints_openapi_tabla.txt_tabla.txt")

    # TSV: endpoint	archivo	linea	framework
    with open(tsv_path, "w", encoding="utf-8") as f:
        f.write("endpoint\tarchivo\tlinea\tframework\n")
        for ep, method in endpoints:
            fw = "OpenAPI" if method is None else f"OpenAPI {method}"
            f.write(f"{ep}\t{source_path}\t0\t{fw}\n")

    # Tabla alineada
    if endpoints:
        max_ep = max(len(ep) for ep, _ in endpoints)
        max_src = len(source_path)
        max_line = len("0")
        fmt = f"{{:<{max_ep+2}}} {{:<{max_src+2}}} {{:>{max_line}}}"
        with open(tabla_path, "w", encoding="utf-8") as tf:
            tf.write(fmt.format("Endpoint", "Ruta archivo", "Línea archivo") + "\n")
            tf.write("-" * (max_ep + max_src + max_line + 4) + "\n")
            for ep, _ in endpoints:
                tf.write(fmt.format(ep, source_path, "0") + "\n")

    return tsv_path, tabla_path


def main():
    # Por defecto, usar el archivo dbapi-SCT.json del repositorio del usuario
    default_src = "/home/markmur88/api_bank_h2/temp/scripts/validacion/dbapi-SCT.json"
    out_dir = "/home/markmur88/endpoints/reportes"

    src = default_src
    if len(sys.argv) > 1 and sys.argv[1].strip():
        src = sys.argv[1]

    if len(sys.argv) > 2 and sys.argv[2].strip():
        out_dir = sys.argv[2]

    if not os.path.isfile(src):
        print(f"Error: No existe el archivo OpenAPI: {src}")
        sys.exit(1)

    try:
        doc = load_openapi(src)
    except Exception as e:
        print(f"Error cargando OpenAPI: {e}")
        sys.exit(1)

    endpoints = extract_endpoints_from_openapi(doc)
    tsv, tabla = write_reports(endpoints, src, out_dir)
    print(f"Total extraídos: {len(endpoints)}")
    print(f"TSV:   {tsv}")
    print(f"Tabla: {tabla}")


if __name__ == "__main__":
    main()


