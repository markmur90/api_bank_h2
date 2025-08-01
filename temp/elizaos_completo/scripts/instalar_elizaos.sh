#!/bin/bash

echo "🚀 Iniciando instalación de ElizaOS en puerto 9182..."

# Configurar ElizaOS en el VPS
ssh -i vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "📁 Configurando directorio de ElizaOS..."
cd eliza-develop

echo "⚙️ Configurando variables de entorno..."
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

echo "🛑 Deteniendo procesos anteriores..."
pkill -f "node.*eliza" || true
sleep 2

echo "🚀 Iniciando ElizaOS en puerto 9182..."
cd packages/cli
nohup node dist/index.js start --port 9182 > /tmp/elizaos.log 2>&1 &

echo "⏳ Esperando que ElizaOS se inicie..."
sleep 5

echo "🔍 Verificando estado..."
if pgrep -f "node.*eliza" > /dev/null; then
    echo "✅ ElizaOS iniciado correctamente!"
    echo "🌐 Accesible en: http://amara.coretransapi.com:9182"
    echo "🌐 Accesible en: http://80.78.30.242:9182"
    
    echo "📊 Estado del puerto:"
    netstat -tlnp | grep :9182 || echo "⚠️ Puerto 9182 no detectado"
    
    echo "📋 Logs recientes:"
    tail -10 /tmp/elizaos.log
else
    echo "❌ Error al iniciar ElizaOS"
    echo "📋 Logs de error:"
    cat /tmp/elizaos.log
fi

EOF

echo "🎉 Instalación completada!"
echo "🌐 Accede a ElizaOS en: http://amara.coretransapi.com:9182" 