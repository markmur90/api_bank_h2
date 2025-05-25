#!/bin/bash

# === CONFIGURACIÓN SEGÚN MODO ===
MODO="dev"
if [[ "$1" == "--prod" ]]; then
  MODO="prod"
fi

# === VARIABLES DEPENDIENTES DEL MODO ===
if [[ "$MODO" == "prod" ]]; then
  echo "🌐 Ejecutando en MODO PRODUCCIÓN..."
  OUTPUT="resultado_jwt_prod.txt"
  JWT_FILE="client_assertion_prod.jwt"
  RESPONSE_FILE="access_token_prod.json"
  TOKEN_ENDPOINT="https://api.db.com/gw/oidc/token"
  SCOPE="sepa_credit_transfers read_accounts"
  FIRMAR_SCRIPT="firmar_jwt_prod.py"
else
  echo "🌐 Ejecutando en MODO DESARROLLO..."
  OUTPUT="resultado_jwt.txt"
  JWT_FILE="client_assertion.jwt"
  RESPONSE_FILE="access_token.json"
  TOKEN_ENDPOINT="https://simulator-api.db.com/gw/oidc/token"
  SCOPE="sepa_credit_transfers"
  FIRMAR_SCRIPT="firmar_jwt.py"
fi

CLIENT_ASSERTION_TYPE="urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

echo "🧨 Iniciando ejecución completa..." > $OUTPUT

# === 1. Generar JWKS ===
echo "🚀 1. Generando claves y JWKS..."
python3 crear_jwks.py >> $OUTPUT 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Error al generar JWKS. Abortando." | tee -a $OUTPUT
  exit 1
fi

# === 2. Firmar JWT ===
echo -e "\n🔐 2. Firmando JWT..." | tee -a $OUTPUT
python3 $FIRMAR_SCRIPT >> $OUTPUT 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Error al firmar JWT. Abortando." | tee -a $OUTPUT
  exit 1
fi

if [ ! -f "client_assertion.jwt" ]; then
  echo "❌ No se encontró el archivo JWT firmado. Abortando." | tee -a $OUTPUT
  exit 1
fi

cp client_assertion.jwt "$JWT_FILE"
JWT_VALUE=$(cat "$JWT_FILE")

echo -e "\n📎 JWT firmado generado:\n" >> $OUTPUT
echo "$JWT_VALUE" >> $OUTPUT

# === 3. Validar JWT ===
echo -e "\n🔍 3. Validando JWT..." | tee -a $OUTPUT
python3 validar_jwt.py >> $OUTPUT 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Error al validar JWT." | tee -a $OUTPUT
  exit 1
fi

# === 4. Imprimir JWKS público ===
echo -e "\n📤 4. JWKS público para subir al portal:" >> $OUTPUT
python3 print_jwks_public.py >> $OUTPUT

# === 5. Enviar client_assertion al token endpoint ===
echo -e "\n🌐 5. Enviando JWT al token endpoint de Deutsche Bank..." | tee -a $OUTPUT

curl -s -X POST $TOKEN_ENDPOINT \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_assertion_type=$CLIENT_ASSERTION_TYPE" \
  -d "client_assertion=$JWT_VALUE" \
  -d "scope=$SCOPE" \
  -o "$RESPONSE_FILE"

echo -e "\n📦 Respuesta guardada en $RESPONSE_FILE\n" | tee -a $OUTPUT
echo -e "\n🔓 Contenido de la respuesta:\n" >> $OUTPUT
cat $RESPONSE_FILE >> $OUTPUT

ACCESS_TOKEN=$(jq -r '.access_token // empty' "$RESPONSE_FILE")

if [ -n "$ACCESS_TOKEN" ]; then
  echo -e "\n✅ Access token recibido:\n$ACCESS_TOKEN" | tee -a $OUTPUT
else
  echo -e "\n❌ No se recibió access token. Revisa los parámetros y el JWKS en el portal." | tee -a $OUTPUT
fi

echo -e "\n🏁 Proceso completado. Archivo resumen: $OUTPUT"
