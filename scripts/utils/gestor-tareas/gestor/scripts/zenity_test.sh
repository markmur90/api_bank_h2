#!/bin/bash
set +e

echo "Ejecutando zenity..."

out=$(zenity --list \
  --checklist \
  --title="Test botón extra" \
  --text="Elegí algo o tocá 'Agregar'" \
  --column="Estado" --column="Item" \
  FALSE "Item A" \
  --extra-button="Agregar" \
  --ok-label="Actualizar" \
  --cancel-label="Salir")

code=$?

echo "----- RESULTADO -----"
echo "STDOUT: $out"
echo "EXIT CODE: $code"
