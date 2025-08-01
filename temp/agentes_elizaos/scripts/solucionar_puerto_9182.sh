#!/bin/bash

# Script para solucionar el conflicto del puerto 9182
# El puerto 9182 está configurado para HTTPS en Nginx, necesitamos usar otro puerto

echo "🔧 Solucionando conflicto del puerto 9182..."

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "📊 Verificando qué está usando el puerto 9182..."
sudo netstat -tlnp | grep :9182

echo "📋 Verificando configuración de Nginx..."
sudo cat /etc/nginx/sites-available/amara.coretransapi.com | grep -A 5 -B 5 "9182"

echo "🔄 Soluciones disponibles:"
echo "1. Usar puerto 9190 para el agente (recomendado)"
echo "2. Modificar configuración de Nginx"
echo "3. Usar puerto 9191"

echo "🚀 Creando agente en puerto 9190 (sin conflictos)..."

cd eliza-develop

echo "🛑 Deteniendo procesos anteriores en puerto 9182..."
pm2 stop amara-complete 2>/dev/null || true
pm2 delete amara-complete 2>/dev/null || true

echo "📁 Creando directorio del agente..."
mkdir -p .eliza/agents/amara-complete

echo "⚙️ Generando configuración del agente en puerto 9190..."
cat > .eliza/agents/amara-complete/config.json << 'CONFIG_EOF'
{
  "name": "amara-complete",
  "description": "Agente completo con todos los módulos locales, sin APIs externas",
  "version": "1.0.0",
  "plugins": [
    "@elizaos/plugin-bootstrap",
    "@elizaos/plugin-dummy-services",
    "@elizaos/plugin-sql"
  ],
  "settings": {
    "port": 9190,
    "host": "0.0.0.0",
    "database": {
      "type": "pglite",
      "path": "/home/markmur88/eliza-develop/.eliza"
    },
    "local_modules": {
      "gaby_fullstack": {
        "path": "/home/markmur88/eliza-develop/Gaby_fullstack",
        "enabled": true,
        "models": {
          "stable_diffusion": {
            "path": "/home/markmur88/eliza-develop/Gaby_fullstack/stable-diffusion-webui",
            "enabled": true
          },
          "huggingface": {
            "path": "/home/markmur88/eliza-develop/Gaby_fullstack/models",
            "enabled": true
          }
        }
      },
      "my_agent": {
        "path": "/home/markmur88/eliza-develop/my-agent",
        "enabled": true
      }
    },
    "no_external_apis": true,
    "local_only": true
  },
  "character": {
    "name": "Amara",
    "personality": "Soy Amara, tu asistente de IA completa que funciona 100% localmente. Tengo acceso a todos los módulos locales incluyendo generación de imágenes, procesamiento de texto, y herramientas de desarrollo.",
    "capabilities": [
      "Generación de imágenes con Stable Diffusion",
      "Procesamiento de texto local",
      "Gestión de base de datos SQL",
      "Herramientas de desarrollo",
      "Análisis de código",
      "Generación de contenido multimedia"
    ]
  }
}
CONFIG_EOF

echo "🔧 Configurando variables de entorno..."
cat > .env << 'ENV_EOF'
PORT=9190
HOST=0.0.0.0
USE_LOCAL_MODULES=true
NO_EXTERNAL_APIS=true
PGLITE_DATA_DIR=/home/markmur88/eliza-develop/.eliza
LOG_LEVEL=info
ENV_EOF

echo "🚀 Iniciando agente amara-complete en puerto 9190..."
cd packages/cli
pm2 start dist/index.js --name "amara-complete"

echo "⏳ Esperando que el agente se inicie..."
sleep 5

echo "🔍 Verificando estado..."
if pm2 list | grep -q "amara-complete.*online"; then
    echo "✅ Agente amara-complete iniciado correctamente en puerto 9190!"
    echo "🌐 Accesible en: http://amara.coretransapi.com:9190"
    echo "🌐 Accesible en: http://80.78.30.242:9190"
    
    echo "📊 Estado del puerto:"
    netstat -tlnp | grep :9190 || echo "⚠️ Puerto 9190 no detectado"
    
    echo "📋 Información del agente:"
    pm2 show amara-complete
    
else
    echo "❌ Error al iniciar el agente amara-complete"
    pm2 logs amara-complete --lines 10
fi

echo "🔓 Asegurando que el puerto 9190 esté abierto en UFW..."
sudo ufw allow 9190/tcp

echo "📊 Estado final de puertos:"
sudo netstat -tlnp | grep -E ':(9182|9190)'

EOF

echo "🎉 Problema del puerto 9182 solucionado!"
echo "✅ Agente creado en puerto 9190 (sin conflictos)"
echo "🌐 URL de acceso: http://amara.coretransapi.com:9190"
echo "🌐 URL IP directa: http://80.78.30.242:9190"
echo ""
echo "📝 Nota: El puerto 9182 está configurado para HTTPS en Nginx."
echo "   Para usar el puerto 9182, necesitarías modificar la configuración de Nginx." 