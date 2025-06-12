#!/bin/bash
# backup_logs.sh - Copia logs críticos y los comprime con fecha

DATE=$(date +%Y-%m-%d)
BACKUP_DIR="/var/backups/netlogs"
mkdir -p "$BACKUP_DIR"

tar czf $BACKUP_DIR/logs_$DATE.tar.gz /var/log/ufw.log /var/log/auth.log /var/log/suricata/eve.json
echo "📦 Backup listo: $BACKUP_DIR/logs_$DATE.tar.gz"
