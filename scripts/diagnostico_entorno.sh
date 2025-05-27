#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
LOG_FILE="./scripts/logs/01_full_deploy/full_deploy.log"

mkdir -p "$(dirname "$LOG_FILE")"

{
echo ""
echo -e "📅 Fecha de ejecución: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "📄 Script: $SCRIPT_NAME"
echo -e "═════════════════════════════════════════════════════════════"
} | tee -a "$LOG_FILE"

trap 'echo -e "\n❌ Error en línea $LINENO: \"$BASH_COMMAND\"\nAbortando ejecución." | tee -a "$LOG_FILE"; exit 1' ERR

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SISTEMA="$SCRIPT_DIR/logs/sistema/$(basename "$0" .sh)_.log"
mkdir -p "$(dirname $LOG_SISTEMA)"


echo "🔍 Diagnóstico del entorno para api_bank_h2" | tee -a $LOG_SISTEMA
echo "Fecha: $(date)" | tee -a $LOG_SISTEMA
echo "" | tee -a $LOG_SISTEMA

# Verificar estado del entorno virtual
echo "🧪 Verificando entorno virtual..." | tee -a $LOG_SISTEMA
VENV="$HOME/Documentos/Entorno/envAPP"
if [[ -d "$VENV" ]]; then
    echo "✅ Entorno virtual encontrado: $VENV" | tee -a $LOG_SISTEMA
else
    echo "❌ Entorno virtual NO encontrado" | tee -a $LOG_SISTEMA
fi

# Verificar puertos comunes
echo "" | tee -a $LOG_SISTEMA
echo "🔌 Puertos en uso (8000, 8011, 8443):" | tee -a $LOG_SISTEMA
for port in 8000 8011 8443; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "✅ Puerto $port en uso" | tee -a $LOG_SISTEMA
    else
        echo "⚠️ Puerto $port libre" | tee -a $LOG_SISTEMA
    fi
done

# Verificar servicio Gunicorn
echo "" | tee -a $LOG_SISTEMA
echo "🔥 Verificando proceso Gunicorn..." | tee -a $LOG_SISTEMA
pgrep gunicorn && echo "✅ Gunicorn activo" || echo "❌ Gunicorn no activo"

# Verificar estado de Nginx
echo "" | tee -a $LOG_SISTEMA
echo "🧭 Verificando estado de Nginx..." | tee -a $LOG_SISTEMA
sudo systemctl is-active nginx && echo "✅ Nginx activo" || echo "❌ Nginx no activo"

# Verificar estado del firewall
echo "" | tee -a $LOG_SISTEMA
echo "🛡 Verificando reglas de UFW..." | tee -a $LOG_SISTEMA
sudo ufw status

# Verificar conectividad con PostgreSQL
echo "" | tee -a $LOG_SISTEMA
echo "🗄 Verificando conexión a PostgreSQL local..." | tee -a $LOG_SISTEMA
PGUSER=markmur88 psql -d postgres -c '\conninfo' 2>/dev/null || echo "❌ Conexión fallida"

# Verificar certificados
echo "" | tee -a $LOG_SISTEMA
echo "🔐 Verificando certificados SSL..." | tee -a $LOG_SISTEMA
CERT_PATH="$HOME/Documentos/GitHub/api_bank_h2/certs/desarrollo.crt"
[[ -f "$CERT_PATH" ]] && echo "✅ Certificado encontrado: $CERT_PATH" || echo "❌ Certificado no encontrado"

echo "" | tee -a $LOG_SISTEMA
echo "✅ Diagnóstico finalizado." | tee -a $LOG_SISTEMA
