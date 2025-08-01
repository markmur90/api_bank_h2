#!/bin/bash

# Script de instalación completa de ElizaOS
# Se ejecuta desde el VPS después de subir los archivos
echo "🚀 INSTALACIÓN COMPLETA DE ELIZAOS"
echo "=================================="

echo "📋 Verificando archivos..."
if [ ! -f "configs/agente_completo.json" ]; then
    echo "❌ Error: No se encuentra configs/agente_completo.json"
    exit 1
fi

if [ ! -f "scripts/instalar_elizaos.sh" ]; then
    echo "❌ Error: No se encuentra scripts/instalar_elizaos.sh"
    exit 1
fi

echo "✅ Archivos verificados"

echo ""
echo "🔧 1. INSTALANDO ELIZAOS BÁSICO"
echo "-------------------------------"
./scripts/instalar_elizaos.sh

echo ""
echo "🔧 2. CONFIGURANDO VERSIÓN COMPLETA"
echo "----------------------------------"
./scripts/configurar_version_completa.sh

echo ""
echo "🤖 3. CREANDO AGENTE COMPLETO"
echo "----------------------------"
./scripts/crear_agente_completo.sh

echo ""
echo "🔧 4. CONFIGURANDO SISTEMA DE AGENTES"
echo "------------------------------------"
if [ -d "agentes_elizaos" ]; then
    echo "📁 Navegando al sistema de agentes..."
    cd agentes_elizaos
    
    echo "🔧 Instalando plugins..."
    ./scripts/instalar_plugins.sh
    
    echo "🔓 Configurando UFW..."
    ./scripts/configurar_ufw.sh
    
    echo "🚀 Levantando sistema completo..."
    ./scripts/levantar_sistema_completo.sh
    
    cd ..
else
    echo "⚠️ Carpeta agentes_elizaos no encontrada"
fi

echo ""
echo "🔍 5. VERIFICACIÓN FINAL"
echo "-----------------------"
echo "📊 Estado de PM2:"
pm2 list

echo ""
echo "🌐 Puertos en uso:"
netstat -tlnp | grep -E ':(918[2-7]|919[0-1])' || echo "No hay puertos de agentes activos"

echo ""
echo "🔓 Estado de UFW:"
sudo ufw status

echo ""
echo "🎉 ¡INSTALACIÓN COMPLETADA!"
echo "=========================="
echo ""
echo "🌐 URLs de acceso:"
echo "   - ElizaOS Básico: http://amara.coretransapi.com:9182"
echo "   - Agente Completo: http://amara.coretransapi.com:9190"
echo "   - Agentes Especializados: http://amara.coretransapi.com:9183-9187"
echo ""
echo "📋 Comandos útiles:"
echo "   - Ver agentes: pm2 list"
echo "   - Ver logs: pm2 logs [nombre-agente]"
echo "   - Reiniciar: pm2 restart [nombre-agente]"
echo "   - Diagnóstico: ./agentes_elizaos/scripts/diagnostico_completo.sh"
echo ""
echo "✅ ¡ElizaOS está completamente instalado y funcionando!" 