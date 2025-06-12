# /home/markmur88/api_bank_h2/scripts/utils/simulator_bank/config/gunicorn.conf.py

bind = "0.0.0.0:9181"
workers = 3
worker_class = "sync"
timeout = 30
chdir = "/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/simulador_banco"

accesslog = "/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/logs/gunicorn_access.log"
errorlog = "/home/markmur88/api_bank_h2/scripts/utils/simulator_bank/logs/gunicorn_error.log"
loglevel = "info"

reload = True  # útil en desarrollo
