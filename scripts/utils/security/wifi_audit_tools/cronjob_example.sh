#!/bin/bash
cd /opt/wifi_audit_tools
python3 audit_firewall_logs.py > firewall_report.txt
python3 parse_ids_alerts.py > ids_report.txt
python3 analyze_phishing_logs.py > mail_report.txt

# (Opcional) enviar por correo o subir a Drive
# mail -s "Reporte Seguridad Diaria" it@empresa.com < firewall_report.txt
