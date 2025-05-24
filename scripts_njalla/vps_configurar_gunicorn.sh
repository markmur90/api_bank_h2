#!/bin/bash
set -e

echo "🔧 Gunicorn systemd..."
cat > /etc/systemd/system/gunicorn.service <<EOF
[Unit]
Description=Gunicorn daemon para api_bank_h2
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/root/api_bank_h2
ExecStart=/root/venvAPI/bin/gunicorn --access-logfile - --workers 3 --bind unix:/root/api_bank_h2/api.sock config.wsgi:application

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn
