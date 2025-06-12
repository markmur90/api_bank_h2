#!/bin/bash
# wifi_hardening_check.sh - Verifica configuraciones débiles en APs

iface="wlan0"
echo "🛠️ Verificando configuración de $iface..."

iwlist $iface scanning | grep -E "Encryption|WPA|WPS" > config_check.txt
echo "✅ Configuraciones exportadas a config_check.txt"
