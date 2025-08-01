#!/bin/bash

echo "🧹 Limpiando versiones incompletas..."
ssh -i vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

# Detener todos los procesos de ElizaOS
pm2 stop eliza 2>/dev/null || true
pm2 delete eliza 2>/dev/null || true
pkill -f "node.*eliza" 2>/dev/null || true
pkill -f "node.*ts-node" 2>/dev/null || true

# Eliminar directorio vacío
rm -rf /home/markmur88/eliza 2>/dev/null || true

echo "⚙️ Configurando versión completa en eliza-develop..."

# Ir al directorio de la versión completa
cd eliza-develop

# Configurar variables de entorno para puerto 9182
cat > .env << 'ENV_CONFIG'
# Configuración de ElizaOS para puerto 9182
PORT=9182
HOST=0.0.0.0

# Configuración de base de datos
PGLITE_DATA_DIR=/home/markmur88/eliza-develop/.eliza

# Configuración de logging
LOG_LEVEL=info

# Configuración de modelos (usando Venice.ai)
VENICE_API_KEY="e_lHp9AjvdVCRv1nmN4jGXrh_bYwpFVrw7Avpx84uH"
CHAT_MODEL="venice-uncensored"
IMAGE_MODEL="flux-dev"

# Configuración de Telegram
TELEGRAM_BOT_TOKEN="7881009139:AAH1mokuP0AjmCbd_tN3VJIxVkG7Fq95j5o"
CHAT_ID="769077177"

# Configuración de SadTalker
SADTALKER_MODEL_PATH="/home/markmur88/eliza-develop/SadTalker/checkpoints"
SADTALKER_AUDIO_PATH="/home/markmur88/eliza-develop/audio"
SADTALKER_OUTPUT_PATH="/home/markmur88/eliza-develop/videos"
ENV_CONFIG

echo "🚀 Iniciando ElizaOS desde la versión completa..."
cd packages/cli

# Iniciar ElizaOS con PM2 para gestión automática
pm2 start dist/index.js --name "elizaos-completo" -- --port 9182

echo "⏳ Esperando que ElizaOS se inicie..."
sleep 5

echo "🔍 Verificando estado..."
if pm2 list | grep -q "elizaos-completo.*online"; then
    echo "✅ ElizaOS iniciado correctamente desde la versión completa!"
    echo "🌐 Accesible en: http://amara.coretransapi.com:9182"
    echo "🌐 Accesible en: http://80.78.30.242:9182"
    
    echo "📊 Estado del puerto:"
    netstat -tlnp | grep :9182 || echo "⚠️ Puerto 9182 no detectado"
    
    echo "📋 Información del proceso:"
    pm2 show elizaos-completo
    
    echo "🎯 Módulos disponibles:"
    echo "   - Gaby_fullstack/ (Thor Toys y módulos de IA)"
    echo "   - my-agent/ (Agentes personalizados)"
    echo "   - packages/ (Módulos principales)"
    echo "   - .eliza/ (Configuración y base de datos)"
else
    echo "❌ Error al iniciar ElizaOS"
    pm2 logs elizaos-completo --lines 10
fi

EOF

echo "🎉 Configuración completada!"
echo "🌐 Accede a ElizaOS en: http://amara.coretransapi.com:9182" 