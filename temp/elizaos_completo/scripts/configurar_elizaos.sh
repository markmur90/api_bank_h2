#!/bin/bash

# Script para configurar ElizaOS en el puerto 9182
echo "Configurando ElizaOS en el puerto 9182..."

# Conectar al VPS y configurar
ssh -i vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

# Ir al directorio de ElizaOS
cd eliza-develop

# Configurar el puerto en .env
echo "PORT=9182" >> .env

# Detener cualquier proceso de ElizaOS que esté corriendo
pkill -f "node.*eliza" || true

# Iniciar ElizaOS en el puerto 9182
cd packages/cli
nohup node dist/index.js start --port 9182 > /tmp/elizaos.log 2>&1 &

# Verificar que está corriendo
sleep 3
if pgrep -f "node.*eliza" > /dev/null; then
    echo "✅ ElizaOS iniciado correctamente en el puerto 9182"
    echo "🌐 Accesible en: http://amara.coretransapi.com:9182"
    echo "🌐 Accesible en: http://80.78.30.242:9182"
else
    echo "❌ Error al iniciar ElizaOS"
    cat /tmp/elizaos.log
fi

# Mostrar el estado del puerto
netstat -tlnp | grep :9182 || echo "Puerto 9182 no está abierto"

EOF

echo "Configuración completada!" 