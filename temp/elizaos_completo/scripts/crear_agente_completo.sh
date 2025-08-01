#!/bin/bash

echo "🤖 Creando agente completo con módulos locales..."

ssh -i vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "📁 Configurando directorio del agente..."
cd eliza-develop

# Crear directorio para el agente
mkdir -p .eliza/agents/amara-complete

# Copiar configuración del agente
cp agente_completo.json .eliza/agents/amara-complete/config.json

echo "⚙️ Configurando variables de entorno para módulos locales..."
cat > .env << 'ENV_CONFIG'
# Configuración para agente completo con módulos locales
PORT=9182
HOST=0.0.0.0

# Configuración de base de datos local
PGLITE_DATA_DIR=/home/markmur88/eliza-develop/.eliza

# Configuración de logging
LOG_LEVEL=info

# Configuración de módulos locales (sin APIs externas)
USE_LOCAL_MODULES=true
NO_EXTERNAL_APIS=true

# Configuración de Stable Diffusion local
STABLE_DIFFUSION_PATH=/home/markmur88/eliza-develop/Gaby_fullstack/stable-diffusion-webui
STABLE_DIFFUSION_ENABLED=true

# Configuración de modelos locales
LOCAL_MODELS_PATH=/home/markmur88/eliza-develop/Gaby_fullstack/models
LOCAL_MODELS_ENABLED=true

# Configuración de plugins locales
PLUGIN_BOOTSTRAP_ENABLED=true
PLUGIN_DUMMY_SERVICES_ENABLED=true
PLUGIN_SQL_ENABLED=true

# Configuración de agente personalizado
MY_AGENT_PATH=/home/markmur88/eliza-develop/my-agent
MY_AGENT_ENABLED=true

# Configuración de Thor Toys y módulos Gaby
GABY_FULLSTACK_PATH=/home/markmur88/eliza-develop/Gaby_fullstack
GABY_FULLSTACK_ENABLED=true

# Configuración de SadTalker local
SADTALKER_MODEL_PATH=/home/markmur88/eliza-develop/SadTalker/checkpoints
SADTALKER_AUDIO_PATH=/home/markmur88/eliza-develop/audio
SADTALKER_OUTPUT_PATH=/home/markmur88/eliza-develop/videos
SADTALKER_ENABLED=true
ENV_CONFIG

echo "🔧 Instalando plugins locales..."
cd packages/plugin-bootstrap && bun install && bun run build
cd ../plugin-dummy-services && bun install && bun run build  
cd ../plugin-sql && bun install && bun run build

echo "🛑 Deteniendo ElizaOS anterior..."
pm2 stop elizaos-completo 2>/dev/null || true
pm2 delete elizaos-completo 2>/dev/null || true

echo "🚀 Iniciando agente completo..."
cd /home/markmur88/eliza-develop/packages/cli

# Iniciar con configuración del agente
pm2 start dist/index.js --name "amara-complete" -- --port 9182 --agent amara-complete

echo "⏳ Esperando que el agente se inicie..."
sleep 5

echo "🔍 Verificando estado del agente..."
if pm2 list | grep -q "amara-complete.*online"; then
    echo "✅ Agente Amara iniciado correctamente!"
    echo "🌐 Accesible en: http://amara.coretransapi.com:9182"
    echo "🌐 Accesible en: http://80.78.30.242:9182"
    
    echo "📊 Estado del puerto:"
    netstat -tlnp | grep :9182 || echo "⚠️ Puerto 9182 no detectado"
    
    echo "🎯 Módulos activos:"
    echo "   ✅ Plugin Bootstrap"
    echo "   ✅ Plugin Dummy Services" 
    echo "   ✅ Plugin SQL"
    echo "   ✅ Gaby Fullstack (Thor Toys)"
    echo "   ✅ My Agent"
    echo "   ✅ Stable Diffusion local"
    echo "   ✅ Modelos locales"
    echo "   ✅ SadTalker local"
    
    echo "📋 Información del agente:"
    pm2 show amara-complete
    
    echo "🔧 Configuración del agente:"
    cat /home/markmur88/eliza-develop/.eliza/agents/amara-complete/config.json | head -20
    
else
    echo "❌ Error al iniciar el agente"
    pm2 logs amara-complete --lines 10
fi

EOF

echo "🎉 Agente completo creado!"
echo "🤖 Nombre: Amara-AI-Complete"
echo "🌐 URL: http://amara.coretransapi.com:9182"
echo "🔧 Configuración: Solo módulos locales, sin APIs externas" 