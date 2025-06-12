#!/bin/bash

# Configuración
VPS_PUBLIC_IP="80.78.30.242"
VPS_INTERNAL_IP="193.150.168.10"
LOCAL_IP="127.0.0.1"
LOCAL_PORT=400

function local_to_local {
    echo ">> Probando Local a Local..."
    curl -H "Host: $LOCAL_IP" http://$LOCAL_IP:$LOCAL_PORT/
}

function local_to_vps {
    echo ">> Probando Local a VPS..."
    curl -H "Host: $VPS_PUBLIC_IP" http://$VPS_PUBLIC_IP:$LOCAL_PORT/
}

function vps_to_vps {
    echo ">> Probando VPS a VPS (red 193.150)..."
    curl -H "Host: $VPS_INTERNAL_IP" http://$VPS_INTERNAL_IP:$LOCAL_PORT/
}

function vps_to_local {
    echo ">> Probando VPS a Local (esto depende de conectividad inversa)..."
    read -p "IP local accesible desde VPS: " LOCAL_HOST
    read -p "Puerto local (ej. 400): " LOCAL_PORT_REMOTE
    curl -H "Host: $LOCAL_HOST" http://$LOCAL_HOST:$LOCAL_PORT_REMOTE/
}

echo "=== Menú de Test de Acceso al Simulador ==="
select opt in "Local -> Local" "Local -> VPS" "VPS -> VPS" "VPS -> Local" "Salir"; do
    case $REPLY in
        1) local_to_local ;;
        2) local_to_vps ;;
        3) vps_to_vps ;;
        4) vps_to_local ;;
        5) echo "Saliendo..."; exit ;;
        *) echo "Opción inválida";;
    esac
    echo -e "\n---\n"
done
