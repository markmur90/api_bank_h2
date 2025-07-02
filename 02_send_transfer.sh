#!/usr/bin/env bash
# send_transfer.sh — Envía transferencia SEPA al simulador

# Requiere: SIM_TOKEN exportado
if [[ -z "$SIM_TOKEN" ]]; then
  echo "❌ Variable SIM_TOKEN no definida. Ejecuta primero ./login.sh"
  exit 1
fi

# Datos de la transferencia
API_URL="http://localhost:3000/api/transferencia/"
IDEMP_ID="206df230-f289-4d27-a2a5-27131ee68d72"

# Leer OTP manualmente
read -p "🔢 Introduce el OTP para la transferencia $IDEMP_ID: " OTP

echo "✉️ Enviando transferencia..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SIM_TOKEN" \
  -H "Idempotency-Id: $IDEMP_ID" \
  -H "Correlation-Id: $IDEMP_ID" \
  -H "Otp: $OTP" \
  -d @transfer.json)

# Separar cuerpo y código HTTP
HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "202" ]]; then
  echo "❌ Error al enviar transferencia (HTTP $HTTP_CODE):"
  echo "$HTTP_BODY"
  exit 1
fi

echo "✅ Transferencia iniciada (HTTP $HTTP_CODE):"
echo "$HTTP_BODY"
