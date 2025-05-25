#!/bin/bash

echo "🚀 1. Generando claves y JWKS..."
python3 crear_jwks.py
if [ $? -ne 0 ]; then
  echo "❌ Error al generar JWKS. Abortando."
  exit 1
fi

echo ""
echo "🔐 2. Firmando JWT..."
python3 firmar_jwt.py
if [ $? -ne 0 ]; then
  echo "❌ Error al firmar el JWT. Abortando."
  exit 1
fi

echo ""
echo "🔍 3. Validando JWT firmado..."
python3 validar_jwt.py
if [ $? -ne 0 ]; then
  echo "❌ Error al validar el JWT. Abortando."
  exit 1
fi

echo ""
echo "✅ Proceso completado con éxito."
