import os
from pathlib import Path
from dotenv import load_dotenv

# ============================ #
#         GENERAL SETUP        #
# ============================ #

CONFIG_PATH = Path(__file__).resolve()
BASE_DIR = CONFIG_PATH.parent
PROJECT_NAME = "api_bank_h2"
PROJECT_NAME_SOCK = "api"

# Cargar .env
dotenv_path = BASE_DIR / ".env"
if dotenv_path.exists():
    load_dotenv(dotenv_path)
else:
    raise FileNotFoundError(f"Archivo de entorno no encontrado: {dotenv_path}")

ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
PORT = os.getenv("PORT")
INTERFAZ = os.getenv("INTERFAZ")
TOR_PASS = os.getenv("TOR_PASS")

if not PORT or not INTERFAZ or not TOR_PASS:
    raise EnvironmentError("Faltan variables críticas en el archivo .env: PORT, INTERFAZ o TOR_PASS")

# ============================ #
#          DIRECTORIOS         #
# ============================ #

VENV_DIR = "/home/markmur88/Documentos/Entorno/envAPP"
SCRIPTS_DIR = BASE_DIR / "scripts"
SERVERS_DIR = BASE_DIR / "servers"
CACHE_DIR = BASE_DIR / "tmp"
LOG_DIR = BASE_DIR / "logs"

# ============================ #
#         GUNICORN             #
# ============================ #

GUNICORN_DIR = SERVERS_DIR / "gunicorn"
SOCK_FILE = GUNICORN_DIR / f"{PROJECT_NAME_SOCK}.sock"
GUNICORN_LOG = GUNICORN_DIR / "gunicorn.log"
GUNICORN_PIDFILE = LOG_DIR / "gunicorn.pid"
GUNICORN_SERVICE_NAME = f"{PROJECT_NAME}_gunicorn"
GUNICORN_CONF = GUNICORN_DIR / "gunicorn.conf.py"
GUNICORN_SERVICE_FILE = GUNICORN_DIR / "gunicorn.service"
GUNICORN_SOCKET_FILE = GUNICORN_DIR / "gunicorn.socket"

# ============================ #
#           LOGGING            #
# ============================ #

RED_LOG = LOG_DIR / "red.log"
ERROR_LOG = LOG_DIR / "error.log"
CRON_LOG = LOG_DIR / "cron.log"
RUNNER_LOG = LOG_DIR / "runner.log"
OPERATION_LOG = LOG_DIR / "operation.log"
STARTUP_LOG = LOG_DIR / "startup.log"

# ============================ #
#         SUPERVISOR           #
# ============================ #

SUPERVISOR_DIR = SERVERS_DIR / "supervisor" / "conf.d"
SUPERVISOR_SERVICE_NAME = GUNICORN_SERVICE_NAME
SUPERVISOR_CONF = SUPERVISOR_DIR / f"{SUPERVISOR_SERVICE_NAME}.conf"

# ============================ #
#            NGINX             #
# ============================ #

NGINX_SITES_AVAILABLE = SERVERS_DIR / "nginx" / "sites-available"
NGINX_SITES_ENABLED = Path(os.getenv("NGINX_SITES_ENABLED", str(Path.home() / "servers/nginx/sites-enabled")))
NGINX_CONF = NGINX_SITES_AVAILABLE / PROJECT_NAME
NGINX_EXTRA_CONF = NGINX_SITES_AVAILABLE / "nginx_coretransact.conf"

# ============================ #
#             SSL              #
# ============================ #

CERT_DIR = SERVERS_DIR / "ssl" / PROJECT_NAME
SSL_CERT = CERT_DIR / "ghost.crt"
SSL_KEY = CERT_DIR / "ghost.key"

# ============================ #
#             TOR              #
# ============================ #

TOR_CONFIG = SERVERS_DIR / "tor" / "torrc"

# ============================ #
#       ESTADO DE RED          #
# ============================ #

IP_ANT = CACHE_DIR / "ip_antes.txt"
IP_ACT = CACHE_DIR / "ip_actual.txt"
MC_ANT = CACHE_DIR / "mac_antes.txt"
MC_ACT = CACHE_DIR / "mac_actual.txt"

# ============================ #
#       FUNCIONES AUXILIARES   #
# ============================ #

def init_directories():
    for path in [
        GUNICORN_DIR, CACHE_DIR, LOG_DIR,
        SUPERVISOR_DIR, NGINX_SITES_AVAILABLE, CERT_DIR,
        TOR_CONFIG.parent
    ]:
        os.makedirs(path, exist_ok=True)

    destinos_path = BASE_DIR / ".env"
    if destinos_path.exists():
        with open(destinos_path) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or ":" not in line:
                    continue
                ruta_str, nombre = line.split(":", 1)
                entorno_dir = Path(ruta_str.strip())
                entorno_env = entorno_dir / ".env"
                ejemplo = entorno_dir / ".env.example"
                log_file = LOG_DIR / f"{nombre}.log"

                entorno_dir.mkdir(parents=True, exist_ok=True)

                if not ejemplo.exists():
                    with open(ejemplo, "w") as f:
                        f.write(f'''# ⚙️ Archivo de entorno para {nombre.upper()}

PORT="8011"
INTERFAZ="wlan0"
TOR_PASS="CambiarEstaClave"

# Copiar a .env para activar:
# cp .env.example .env
''')

                if not log_file.exists():
                    log_file.touch()

def export_env_for_bash(output_file=".env", environment="local"):
    destinos_path = BASE_DIR / ".env"
    if not destinos_path.exists():
        raise FileNotFoundError("Archivo .env no encontrado")

    entorno_ruta = None
    with open(destinos_path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            ruta, nombre = line.split(":")
            if nombre == environment:
                entorno_ruta = Path(ruta)
                break

    if entorno_ruta is None:
        raise ValueError(f"Entorno '{environment}' no encontrado en .env")

    dotenv_file = entorno_ruta / ".env"
    if not dotenv_file.exists():
        raise FileNotFoundError(f"No se encontró el archivo .env en {entorno_ruta}")

    load_dotenv(dotenv_file)

    port = os.getenv("PORT")
    interfaz = os.getenv("INTERFAZ")
    tor_pass = os.getenv("TOR_PASS")

    if not port or not interfaz or not tor_pass:
        raise EnvironmentError(f"Faltan variables críticas en el archivo .env de {environment}")

    variables = {
        "PORT": port,
        "INTERFAZ": interfaz,
        "TOR_PASS": tor_pass,
        "ENVIRONMENT": environment,
        "PROJECT_NAME": PROJECT_NAME,
        "PROJECT_NAME_SOCK": PROJECT_NAME_SOCK,
    }

    with open(output_file, "w") as f:
        for k, v in variables.items():
            f.write(f'{k}="{v}"\n')

def debug_print_config():
    print("======= CONFIG MASTER =======")
    print(f"CONFIG_PATH:       {CONFIG_PATH}")
    print(f"PROJECT_NAME:      {PROJECT_NAME}")
    print(f"ENVIRONMENT:       {ENVIRONMENT}")
    print(f"PORT:              {PORT}")
    print(f"INTERFAZ:          {INTERFAZ}")
    print(f"TOR_PASS:          {'*' * len(TOR_PASS)}")
    print(f"SOCK_FILE:         {SOCK_FILE}")
    print(f"GUNICORN_CONF:     {GUNICORN_CONF}")
    print(f"GUNICORN_SERVICE:  {GUNICORN_SERVICE_FILE}")
    print(f"GUNICORN_SOCKET:   {GUNICORN_SOCKET_FILE}")
    print(f"SUPERVISOR_CONF:   {SUPERVISOR_CONF}")
    print(f"NGINX_CONF:        {NGINX_CONF}")
    print(f"NGINX_EXTRA_CONF:  {NGINX_EXTRA_CONF}")
    print(f"SSL_CERT:          {SSL_CERT}")
    print(f"SSL_KEY:           {SSL_KEY}")
    print(f"TOR_CONFIG:        {TOR_CONFIG}")
    print("======= END CONFIG =========")

