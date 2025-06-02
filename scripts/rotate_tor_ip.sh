#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURACIÓN ===
CONTROL_PORT="9051"
CONTROL_PASS="Ptf8454Jd55"  # Reemplaza o exporta como variable

echo "🔄 Solicitando nueva identidad a Tor..."

{
    echo "authenticate \"$CONTROL_PASS\""
    echo "signal newnym"
    echo "quit"
} | nc 127.0.0.1 $CONTROL_PORT

echo "✅ Solicitud enviada. Espera ~10 seg para nuevo circuito."
