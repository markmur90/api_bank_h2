import multiprocessing
import os

# Configuración de workers
workers = 4
worker_class = 'sync'
worker_connections = 1000

# Configuración de timeouts
timeout = 30
keepalive = 2
max_requests = 1000
max_requests_jitter = 50

# Configuración de logging
accesslog = '/home/markmur88/api_bank_h2/logs/gunicorn_access.log'
errorlog = '/home/markmur88/api_bank_h2/logs/gunicorn_error.log'
loglevel = 'info'

# Configuración de socket
bind = 'unix:/home/markmur88/api_bank_h2/servers/gunicorn/api.sock'
user = 'markmur88'
group = 'markmur88'

# Configuración de preload
preload_app = True

# Configuración de seguridad
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Configuración de worker
worker_tmp_dir = '/dev/shm'