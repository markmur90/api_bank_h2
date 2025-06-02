#!/usr/bin/env bash
set -e

GREEN="\033[1;32m"
RED="\033[1;31m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${CYAN}🔍 Verificando estado de Tor...${NC}"

# Verifica si tor está instalado
if ! command -v tor &> /dev/null; then
    echo -e "${RED}❌ Tor no está instalado.${NC}"
    exit 1
fi

# Verifica si el servicio Tor está activo
if systemctl is-active --quiet tor; then
    echo -e "${GREEN}✅ Servicio Tor activo${NC}"
else
    echo -e "${RED}❌ Servicio Tor inactivo${NC}"
    exit 1
fi

# Verifica conectividad con puerto SOCKS
if timeout 2 bash -c "</dev/tcp/127.0.0.1/9050"; then
    echo -e "${GREEN}✅ Puerto SOCKS (9050) responde${NC}"
else
    echo -e "${RED}❌ Puerto SOCKS no responde${NC}"
fi

# Verifica generación de hidden_service
HS_FILE="/var/lib/tor/hidden_service/hostname"
if [[ -f "$HS_FILE" ]]; then
    echo -e "${GREEN}✅ Dirección .onion generada:${NC} $(cat $HS_FILE)"
else
    echo -e "${RED}❌ No se encontró la dirección .onion${NC}"
fi

# Verifica errores de configuración
echo -e "${CYAN}📄 Validando configuración torrc...${NC}"
if tor --verify-config &> /dev/null; then
    echo -e "${GREEN}✅ torrc válido${NC}"
else
    echo -e "${RED}❌ Error en torrc. Revisar configuración.${NC}"
fi
