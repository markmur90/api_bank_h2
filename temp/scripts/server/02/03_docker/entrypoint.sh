#!/bin/bash
set -e
python - << 'PYCODE'
import os
from datetime import datetime
import csv
LOG_FILE="honeypot_logs.csv"
if os.path.exists(LOG_FILE):
    os.remove(LOG_FILE)
with open(LOG_FILE,'w',newline='') as f:
    csv.writer(f).writerow(["timestamp","ip","port","protocol","info"])
PYCODE
exec gunicorn -b 0.0.0.0:5000 06_app:app