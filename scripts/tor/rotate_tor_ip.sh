#!/bin/bash
CONTROL_PORT=9051
CONTROL_PASS="Ptf8454Jd55"

echo "🔄 Solicitando nueva identidad a Tor..."

{
    echo "authenticate \"$CONTROL_PASS\""
    echo "signal newnym"
    echo "quit"
} | nc 127.0.0.1 $CONTROL_PORT

echo "✅ Solicitud enviada. Esperá unos segundos para que se establezca un nuevo circuito."
