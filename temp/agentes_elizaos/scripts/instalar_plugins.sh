#!/bin/bash

# Script para instalar y compilar plugins de ElizaOS
# Uso: ./instalar_plugins.sh

echo "🔧 Instalando y compilando plugins de ElizaOS..."

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo "📁 Navegando al directorio de ElizaOS..."
cd eliza-develop

echo "🔧 Activando Bun..."
source ~/.zshrc

echo "📦 Instalando plugin-bootstrap..."
cd packages/plugin-bootstrap
echo "  - Instalando dependencias..."
bun install
echo "  - Compilando plugin..."
bun run build
echo "✅ Plugin Bootstrap instalado y compilado"

echo "📦 Instalando plugin-dummy-services..."
cd ../plugin-dummy-services
echo "  - Instalando dependencias..."
bun install
echo "  - Compilando plugin..."
bun run build
echo "✅ Plugin Dummy Services instalado y compilado"

echo "📦 Instalando plugin-sql..."
cd ../plugin-sql
echo "  - Instalando dependencias..."
bun install
echo "  - Compilando plugin..."
bun run build
echo "✅ Plugin SQL instalado y compilado"

echo "📦 Verificando instalación de plugins..."
cd ..
echo "📋 Plugins disponibles:"
ls -la packages/plugin-*/dist/

echo "🔍 Verificando archivos compilados..."
for plugin in bootstrap dummy-services sql; do
    if [ -f "packages/plugin-$plugin/dist/index.js" ]; then
        echo "✅ Plugin $plugin: OK"
    else
        echo "❌ Plugin $plugin: ERROR - archivo no encontrado"
    fi
done

echo "📊 Estado de los plugins:"
echo "  - Bootstrap: $(ls -la packages/plugin-bootstrap/dist/index.js 2>/dev/null | wc -l) archivos"
echo "  - Dummy Services: $(ls -la packages/plugin-dummy-services/dist/index.js 2>/dev/null | wc -l) archivos"
echo "  - SQL: $(ls -la packages/plugin-sql/dist/index.js 2>/dev/null | wc -l) archivos"

echo "🎉 Instalación de plugins completada!"
echo "📝 Los plugins están listos para ser usados en los agentes"

EOF

echo "✅ Instalación de plugins finalizada"
echo "📋 Plugins instalados:"
echo "   - @elizaos/plugin-bootstrap"
echo "   - @elizaos/plugin-dummy-services"
echo "   - @elizaos/plugin-sql" 