# /home/markmur88/Simulador/config/gunicorn.conf.py

bind = "0.0.0.0:9181"
workers = 3
worker_class = "sync"
timeout = 30
chdir = "/home/markmur88/Simulador/simulador_banco"

accesslog = "/home/markmur88/Simulador/logs/gunicorn_access.log"
errorlog = "/home/markmur88/Simulador/logs/gunicorn_error.log"
loglevel = "info"

reload = True  # útil en desarrollo
