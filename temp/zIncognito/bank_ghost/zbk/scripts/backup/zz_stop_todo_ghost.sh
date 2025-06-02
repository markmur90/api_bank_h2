#!/bin/bash



# 1. x001_deploy_ghost_prod.sh (no requiere sudo)
echo "[1/2] Ejecutando despliegue del proyecto..."
bash z03_detener_ghost.sh || { echo "Fallo en x03_detener_ghost.sh"; exit 1; }



echo ""
echo ""
echo ""
# 2. x002_nginx.sh (requiere sudo)
echo "[2/2] Configurando Nginx..."
bash z04_clean_ghost.sh || { echo "Fallo en z04_clean_ghost.sh"; exit 1; }

echo ""
echo ""


echo "Despliegue detenito completo."
