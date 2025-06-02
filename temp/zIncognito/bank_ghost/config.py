import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

PROJECT_NAME = "bank_ghost"
PROJECT_NAME_SOCK = "ghost"
PORT = "8011"
INTERFAZ = "wlan0"
TOR_PASS = "Ptf8454Jd55"
PROJECT_DIR = BASE_DIR
VENV_DIR = os.path.join(PROJECT_DIR, "venv")
SCRIPTS_DIR = os.path.join(PROJECT_DIR, "scripts")
SERVERS_DIR = os.path.join(PROJECT_DIR, "servers")

GUNICORN_DIR = os.path.join(SERVERS_DIR, "gunicorn")
SOCK_FILE = os.path.join(GUNICORN_DIR, f"{PROJECT_NAME_SOCK}.sock")
GUNICORN_LOG = os.path.join(GUNICORN_DIR, "gunicorn.log")

CACHE_DIR = os.path.join(PROJECT_DIR, "tmp", "ghostcache")
IP_ANT = os.path.join(CACHE_DIR, "ip_antes.txt")
IP_ACT = os.path.join(CACHE_DIR, "ip_actual.txt")
MC_ANT = os.path.join(CACHE_DIR, "mac_antes.txt")
MC_ACT = os.path.join(CACHE_DIR, "mac_actual.txt")





LOG_DIR = os.path.join(PROJECT_DIR, "logs")
LOGFILE = os.path.join(LOG_DIR, "red.log")
ERROR_LOG = os.path.join(LOG_DIR, "error.log")
CRON_LOG = os.path.join(LOG_DIR, "cron.log")
RUNNER_LOG = os.path.join(LOG_DIR, "runner.log")
PIDFILE = os.path.join(LOG_DIR, "gunicorn.pid")
OPERATION_LOG = os.path.join(LOG_DIR, "operation.log")
RED_LOG = os.path.join(LOG_DIR, "red.log")
STARTUP_LOG = os.path.join(LOG_DIR, "startup.log")

REPORT_DIR = os.path.join(PROJECT_DIR, "reports", "ultimos_reconocimientos")

SUPERVISOR_DIR = os.path.join(SERVERS_DIR, "supervisor", "conf.d")
SUPERVISOR_PROGRAM = f"{PROJECT_NAME}_gunicorn"
SUPERVISOR_CONF = os.path.join(SUPERVISOR_DIR, f"{SUPERVISOR_PROGRAM}.conf")
OLD_SUPERVISOR_CONF = os.path.join(SUPERVISOR_DIR, f"{PROJECT_NAME}.conf")

NGINX_SITES_AVAILABLE = os.path.join(SERVERS_DIR, "nginx", "sites-available")
NGINX_SITES_ENABLED = "/etc/nginx/sites-enabled"
NGINX_CONF = os.path.join(NGINX_SITES_AVAILABLE, PROJECT_NAME)

CERT_DIR = os.path.join(SERVERS_DIR, "ssl", PROJECT_NAME)
SSL_CERT = os.path.join(CERT_DIR, "ghost.crt")
SSL_KEY = os.path.join(CERT_DIR, "ghost.key")

TOR_CONFIG = os.path.join(SERVERS_DIR, "tor", "torrc")

APP_URL = f"http://127.0.0.1:{PORT}/ghostrecon/dashboard/"

os.makedirs(os.path.dirname(TOR_CONFIG), exist_ok=True)

for path in (
    GUNICORN_DIR, CACHE_DIR, LOG_DIR, REPORT_DIR,
    SUPERVISOR_DIR, NGINX_SITES_AVAILABLE, CERT_DIR
):
    os.makedirs(path, exist_ok=True)
