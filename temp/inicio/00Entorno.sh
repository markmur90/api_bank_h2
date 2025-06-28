#!/bin/bash
# Inicio

export DATABASE_URL="postgres://markmur88:Ptf8454Jd55@0.0.0.0:5432/mydatabase"

echo "  "

python3 -m venv /home/markmur88/Documentos/Entorno/envAPP

echo "  "

source /home/markmur88/Documentos/Entorno/envAPP/bin/activate

echo "  "


pip3 install -r /home/markmur88/Documentos/GitHub/api_bank_h2/requirements.txt

echo "  "

sudo systemctl enable postgresql

echo "  "

sudo systemctl start postgresql

echo "  "

echo -e "\033[1m✅ ✅ ✅ Environment setup complete. You can now run your Django application.✅ ✅ ✅\033[0m"

echo "  "
