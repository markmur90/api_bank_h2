#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Diagnóstico del entorno para api_bank_h2"
echo "Fecha: $(date)"
echo ""

# Verificar estado del entorno virtual
echo "🧪 Verificando entorno virtual..."
VENV="$HOME/Documentos/Entorno/envAPP"
if [[ -d "$VENV" ]]; then
    echo "✅ Entorno virtual encontrado: $VENV"
else
    echo "❌ Entorno virtual NO encontrado"
fi

# Verificar puertos comunes
echo ""
echo "🔌 Puertos en uso (8000, 8011, 8443):"
for port in 8000 8011 8443; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "✅ Puerto $port en uso"
    else
        echo "⚠️ Puerto $port libre"
    fi
done

# Verificar servicio Gunicorn
echo ""
echo "🔥 Verificando proceso Gunicorn..."
pgrep gunicorn && echo "✅ Gunicorn activo" || echo "❌ Gunicorn no activo"

# Verificar estado de Nginx
echo ""
echo "🧭 Verificando estado de Nginx..."
sudo systemctl is-active nginx && echo "✅ Nginx activo" || echo "❌ Nginx no activo"

# Verificar estado del firewall
echo ""
echo "🛡 Verificando reglas de UFW..."
sudo ufw status

# Verificar conectividad con PostgreSQL
echo ""
echo "🗄 Verificando conexión a PostgreSQL local..."
PGUSER=markmur88 psql -d postgres -c '\conninfo' 2>/dev/null || echo "❌ Conexión fallida"

# Verificar certificados
echo ""
echo "🔐 Verificando certificados SSL..."
CERT_PATH="$HOME/Documentos/GitHub/api_bank_h2/certs/desarrollo.crt"
[[ -f "$CERT_PATH" ]] && echo "✅ Certificado encontrado: $CERT_PATH" || echo "❌ Certificado no encontrado"

echo ""
echo "✅ Diagnóstico finalizado."
