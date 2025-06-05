#!/usr/bin/env bash
# === VARIABLES DE PROYECTO ===
AP_H2_DIR="/home/markmur88/api_bank_h2"
AP_BK_DIR="/home/markmur88/api_bank_h2_BK"
AP_HK_DIR="/home/markmur88/api_bank_heroku"
VENV_PATH="/home/markmur88/envAPP"
SCRIPTS_DIR="$AP_H2_DIR/scripts"
BACKU_DIR="$SCRIPTS_DIR/backup"
CERTS_DIR="$SCRIPTS_DIR/certs"
DP_DJ_DIR="$SCRIPTS_DIR/deploy/django"
DP_GH_DIR="$SCRIPTS_DIR/deploy/github"
DP_HK_DIR="$SCRIPTS_DIR/deploy/heroku"
DP_VP_DIR="$SCRIPTS_DIR/deploy/vps"
SERVI_DIR="$SCRIPTS_DIR/service"
SYSTE_DIR="$SCRIPTS_DIR/src"
TORSY_DIR="$SCRIPTS_DIR/tor"
UTILS_DIR="$SCRIPTS_DIR/utils"
CO_SE_DIR="$UTILS_DIR/conexion_segura_db"
UT_GT_DIR="$UTILS_DIR/gestor-tareas"
SM_BK_DIR="$UTILS_DIR/simulator_bank"
TOKEN_DIR="$UTILS_DIR/token"
GT_GE_DIR="$UT_GT_DIR/gestor"
GT_NT_DIR="$UT_GT_DIR/notify"
GE_LG_DIR="$GT_GE_DIR/logs"
GE_SH_DIR="$GT_GE_DIR/scripts"

BASE_DIR="$AP_H2_DIR"

set -e

echo -e "\n🔍 Verificando configuración de Tor..."

# Verificar si el servicio Tor está activo
if systemctl is-active --quiet tor; then
    echo -e "✅ Tor está activo."
else
    echo -e "❌ Tor no está activo. Iniciando servicio..."
    sudo systemctl start tor
fi

# Verificar existencia del archivo torrc
TORRC_PATH="/etc/tor/torrc"
if [ -f "$TORRC_PATH" ]; then
    echo -e "✅ Archivo de configuración torrc encontrado en $TORRC_PATH."
else
    echo -e "❌ Archivo de configuración torrc no encontrado en $TORRC_PATH."
    exit 1
fi

# Verificar existencia del servicio oculto
HIDDEN_SERVICE_DIR="/var/lib/tor/hidden_service"
if [ -d "$HIDDEN_SERVICE_DIR" ]; then
    echo -e "✅ Directorio de servicio oculto encontrado."
    if [ -f "$HIDDEN_SERVICE_DIR/hostname" ]; then
        echo -e "🧅 Dirección .onion: $(cat $HIDDEN_SERVICE_DIR/hostname)"
    else
        echo -e "⚠️ Archivo hostname no encontrado en el directorio de servicio oculto."
    fi
else
    echo -e "❌ Directorio de servicio oculto no encontrado en $HIDDEN_SERVICE_DIR."
fi

# Verificar puertos en uso
echo -e "\n📡 Puertos en uso por Tor:"
sudo netstat -tulnp | grep tor || echo "No se encontraron puertos en uso por Tor."

echo -e "\n✅ Verificación completada."
