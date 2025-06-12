#!/bin/bash
# detect_rogue_ap.sh - Busca APs sospechosos con el mismo SSID

KNOWN_SSIDS=("OficialCorpWiFi" "CorpInvitados")
iface="wlan0"

echo "🔎 Escaneando posibles APs deshonestos..."
iwlist $iface scanning | grep -E "Cell|ESSID" > all_aps.txt

for ssid in "${KNOWN_SSIDS[@]}"; do
    echo "SSID esperado: $ssid"
    grep -B 1 "$ssid" all_aps.txt
done
