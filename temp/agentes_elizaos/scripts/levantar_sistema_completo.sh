#!/bin/bash

# Script para levantar todo el sistema de agentes ElizaOS desde cero
# Uso: ./levantar_sistema_completo.sh

echo "🚀 LEVANTANDO SISTEMA COMPLETO - Agentes ElizaOS"
echo "================================================"

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "🛑 1. LIMPIANDO PROCESOS ANTERIORES"
echo "-----------------------------------"
pm2 delete all 2>/dev/null || true
echo "✅ Procesos PM2 eliminados"

echo ""
echo "📦 2. VERIFICANDO BUN"
echo "---------------------"
if ! command -v bun &> /dev/null; then
    echo "❌ Bun no encontrado, instalando..."
    curl -fsSL https://bun.sh/install | bash
    source ~/.zshrc
else
    echo "✅ Bun ya está instalado"
fi

echo ""
echo "🔧 3. NAVEGANDO AL DIRECTORIO"
echo "----------------------------"
cd ~/eliza-develop
pwd
ls -la

echo ""
echo "📦 4. INSTALANDO PLUGINS"
echo "-----------------------"
echo "Instalando plugin-bootstrap..."
cd packages/plugin-bootstrap
bun install
bun run build
echo "✅ Plugin Bootstrap instalado"

echo "Instalando plugin-dummy-services..."
cd ../plugin-dummy-services
bun install
bun run build
echo "✅ Plugin Dummy Services instalado"

echo "Instalando plugin-sql..."
cd ../plugin-sql
bun install
bun run build
echo "✅ Plugin SQL instalado"

cd ~/eliza-develop

echo ""
echo "🔓 5. CONFIGURANDO UFW"
echo "---------------------"
sudo ufw allow 9190/tcp
sudo ufw allow 9183/tcp
sudo ufw allow 9184/tcp
sudo ufw allow 9185/tcp
sudo ufw allow 9186/tcp
sudo ufw allow 9187/tcp
sudo ufw reload
echo "✅ UFW configurado"

echo ""
echo "📁 6. CREANDO DIRECTORIOS"
echo "------------------------"
mkdir -p .eliza/agents/amara-complete
echo "✅ Directorios creados"

echo ""
echo "⚙️ 7. CONFIGURANDO AGENTE PRINCIPAL"
echo "----------------------------------"
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

echo "✅ Configuración del agente creada"

echo ""
echo "🔧 8. CONFIGURANDO VARIABLES DE ENTORNO"
echo "-------------------------------------"
cat > .env << 'ENV_EOF'
PORT=9190
HOST=0.0.0.0
USE_LOCAL_MODULES=true
NO_EXTERNAL_APIS=true
PGLITE_DATA_DIR=/home/markmur88/eliza-develop/.eliza
LOG_LEVEL=info
ENV_EOF

echo "✅ Variables de entorno configuradas"

echo ""
echo "🚀 9. INICIANDO AGENTE"
echo "--------------------"
cd packages/cli
pm2 start dist/index.js --name "amara-complete"

echo ""
echo "⏳ 10. ESPERANDO INICIALIZACIÓN"
echo "-----------------------------"
sleep 10

echo ""
echo "🔍 11. VERIFICANDO ESTADO"
echo "------------------------"
pm2 list

echo ""
echo "🌐 12. VERIFICANDO PUERTOS"
echo "-------------------------"
sudo netstat -tlnp | grep :9190

echo ""
echo "📊 13. VERIFICANDO LOGS"
echo "----------------------"
pm2 logs amara-complete --lines 5

EOF

echo ""
echo "🎉 SISTEMA LEVANTADO COMPLETAMENTE"
echo "=================================="
echo ""
echo "🌐 URLs de acceso:"
echo "   - http://amara.coretransapi.com:9190"
echo "   - http://80.78.30.242:9190"
echo ""
echo "📋 Para verificar el estado:"
echo "   - ./scripts/diagnostico_completo.sh"
echo "   - ./scripts/gestionar_agentes.sh list"
echo "   - ./scripts/gestionar_agentes.sh logs amara-complete"
echo ""
echo "✅ ¡El sistema debería estar funcionando ahora!" 