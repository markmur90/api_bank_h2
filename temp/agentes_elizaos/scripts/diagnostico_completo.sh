#!/bin/bash

# Script de diagnóstico completo para agentes ElizaOS
# Uso: ./diagnostico_completo.sh

echo "🔍 DIAGNÓSTICO COMPLETO - Agentes ElizaOS"
echo "=========================================="

ssh -i ../../vps_njalla_nueva markmur88@80.78.30.242 << 'EOF'

echo ""
echo "📊 1. ESTADO DE PM2 Y AGENTES"
echo "-----------------------------"
pm2 list

echo ""
echo "🌐 2. PUERTOS EN USO"
echo "-------------------"
sudo netstat -tlnp | grep -E ':(918[2-7]|919[0-1])' || echo "No hay puertos de agentes activos"

echo ""
echo "🔓 3. ESTADO DE UFW"
echo "------------------"
sudo ufw status

echo ""
echo "📁 4. VERIFICACIÓN DE ARCHIVOS"
echo "-----------------------------"
echo "Directorio ElizaOS:"
ls -la ~/eliza-develop/

echo ""
echo "Agentes configurados:"
ls -la ~/eliza-develop/.eliza/agents/ 2>/dev/null || echo "No hay agentes configurados"

echo ""
echo "Variables de entorno:"
cat ~/eliza-develop/.env 2>/dev/null || echo "Archivo .env no encontrado"

echo ""
echo "📦 5. VERIFICACIÓN DE PLUGINS"
echo "----------------------------"
echo "Plugins instalados:"
ls -la ~/eliza-develop/packages/plugin-*/dist/ 2>/dev/null || echo "Plugins no encontrados"

echo ""
echo "🔧 6. VERIFICACIÓN DE BUN Y NODE"
echo "-------------------------------"
echo "Bun version:"
bun --version 2>/dev/null || echo "Bun no encontrado"

echo "Node version:"
node --version 2>/dev/null || echo "Node no encontrado"

echo ""
echo "💾 7. RECURSOS DEL SISTEMA"
echo "-------------------------"
echo "Memoria disponible:"
free -h

echo ""
echo "Espacio en disco:"
df -h ~/

echo ""
echo "🔄 8. PROCESOS ACTIVOS"
echo "--------------------"
echo "Procesos PM2:"
ps aux | grep pm2 | grep -v grep

echo ""
echo "Procesos Node:"
ps aux | grep node | grep -v grep

echo ""
echo "🚨 9. LOGS RECIENTES"
echo "------------------"
echo "Logs de PM2 (últimas 10 líneas):"
pm2 logs --lines 10 2>/dev/null || echo "No hay logs de PM2"

echo ""
echo "📋 10. CONFIGURACIÓN DE NGINX"
echo "----------------------------"
echo "Configuración del sitio:"
sudo cat /etc/nginx/sites-available/amara.coretransapi.com | grep -A 5 -B 5 "9182\|9190" 2>/dev/null || echo "Configuración no encontrada"

echo ""
echo "✅ DIAGNÓSTICO COMPLETADO"
echo "========================"

EOF

echo ""
echo "🎯 RESUMEN DEL DIAGNÓSTICO"
echo "=========================="
echo ""
echo "Si no hay agentes corriendo, ejecuta:"
echo "1. ./scripts/instalar_plugins.sh"
echo "2. ./scripts/configurar_ufw.sh"
echo "3. ./scripts/solucionar_puerto_9182.sh"
echo ""
echo "Si hay agentes corriendo pero no accesibles:"
echo "1. Verificar UFW: ./scripts/configurar_ufw.sh"
echo "2. Verificar puertos: ./scripts/gestionar_agentes.sh ports"
echo "3. Verificar logs: ./scripts/gestionar_agentes.sh logs [nombre-agente]" 