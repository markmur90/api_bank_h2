#!/bin/bash

# Script para configurar UFW y abrir puertos para agentes ElizaOS
# Uso: ./configurar_ufw.sh

echo "🔧 Configurando UFW para agentes ElizaOS..."

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "📊 Estado actual de UFW:"
sudo ufw status

echo "🔓 Abriendo puertos para agentes ElizaOS..."

# Puerto 9182 - Agente Local
echo "  - Abriendo puerto 9182 (Agente Local)..."
sudo ufw allow 9182/tcp

# Puerto 9183 - Agente Desarrollador Web
echo "  - Abriendo puerto 9183 (Agente Desarrollador Web)..."
sudo ufw allow 9183/tcp

# Puerto 9184 - Agente Escritor Creativo
echo "  - Abriendo puerto 9184 (Agente Escritor Creativo)..."
sudo ufw allow 9184/tcp

# Puerto 9185 - Agente Analista de Datos
echo "  - Abriendo puerto 9185 (Agente Analista de Datos)..."
sudo ufw allow 9185/tcp

# Puerto 9186 - Agente Soporte al Cliente
echo "  - Abriendo puerto 9186 (Agente Soporte al Cliente)..."
sudo ufw allow 9186/tcp

# Puerto 9187 - Agente Marketing
echo "  - Abriendo puerto 9187 (Agente Marketing)..."
sudo ufw allow 9187/tcp

# Puerto 9190 - Puerto alternativo
echo "  - Abriendo puerto 9190 (Puerto alternativo)..."
sudo ufw allow 9190/tcp

echo "🔄 Recargando reglas de UFW..."
sudo ufw reload

echo "📊 Estado final de UFW:"
sudo ufw status

echo "🌐 Verificando puertos abiertos:"
sudo netstat -tlnp | grep -E ':(918[2-7]|9190)'

echo "✅ Configuración de UFW completada!"
echo "📋 Puertos abiertos para agentes:"
echo "   - 9182: Agente Local"
echo "   - 9183: Agente Desarrollador Web"
echo "   - 9184: Agente Escritor Creativo"
echo "   - 9185: Agente Analista de Datos"
echo "   - 9186: Agente Soporte al Cliente"
echo "   - 9187: Agente Marketing"
echo "   - 9190: Puerto alternativo"

EOF

echo "🎉 Configuración de UFW completada!"
echo "🌐 Ahora puedes acceder a los agentes en:"
echo "   - http://amara.coretransapi.com:9182"
echo "   - http://amara.coretransapi.com:9183"
echo "   - http://amara.coretransapi.com:9184"
echo "   - http://amara.coretransapi.com:9185"
echo "   - http://amara.coretransapi.com:9186"
echo "   - http://amara.coretransapi.com:9187"
echo "   - http://amara.coretransapi.com:9190" 