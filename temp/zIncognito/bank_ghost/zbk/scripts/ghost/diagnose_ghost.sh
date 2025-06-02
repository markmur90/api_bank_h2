#!/bin/bash

echo "🧠 Diagnóstico Ghost Recon"
echo "---------------------------"

echo "📡 Dirección IP actual:"
curl -s ifconfig.me
echo

echo "🧪 Verificando conexión Tor..."
torsocks curl -s https://check.torproject.org | grep "Congratulations" \
    && echo "✅ Tor está funcionando correctamente." \
    || echo "❌ Tor NO está funcionando correctamente."

echo "🔍 Dirección MAC actual de eth0:"
ip link show wlan0 | grep ether

echo "📦 Dependencias..."
echo -n "Python: "; which python3
echo -n "Playwright: "; python3 -c "import playwright.sync_api" 2>/dev/null && echo "✅" || echo "❌ NO INSTALADO"
echo -n "Tor: "; which tor
echo -n "macchanger: "; which macchanger

echo "🗂️ Archivos de log:"
ls -lh logs/ | tail -n +2

echo "🖼️ Capturas guardadas:"
ls -lh capturas/ | tail -n +2
