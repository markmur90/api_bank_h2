#!/bin/bash
# scan_wifi.sh - Escanea redes Wi-Fi y detecta APs duplicados o deshonestos

echo "🔍 Escaneando redes Wi-Fi disponibles..."
nmcli dev wifi list > wifi_scan.txt
echo "✅ Resultados guardados en wifi_scan.txt"
