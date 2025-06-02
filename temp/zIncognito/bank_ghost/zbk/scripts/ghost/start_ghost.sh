#!/bin/bash

echo "✅ Iniciando Ghost Recon (sin limpiar)..."

# Reafirmar conexión Tor
echo "🧪 Verificando Tor antes de iniciar..."
torsocks curl -s https://check.torproject.org | grep -q "Congratulations"

if [ $? -ne 0 ]; then
    echo "❌ Tor no está funcionando correctamente."
    exit 1
fi

# Ejecutar ghost_recon
echo "👻 Ejecutando ghost_recon_ultimate.py..."
python3 ghost_recon_ultimate.py "$@"
