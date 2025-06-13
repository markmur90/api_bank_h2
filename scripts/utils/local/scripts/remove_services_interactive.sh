#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Ejecuta este script como root o con sudo"
  exit 1
fi

# Carga los servicios habilitados
mapfile -t SERVICIOS < <(
  systemctl list-unit-files --type=service \
  | awk '$2=="enabled"{print $1}'
)

if [ ${#SERVICIOS[@]} -eq 0 ]; then
  echo "No se encontraron servicios habilitados para procesar."
  exit 0
fi

while :; do
  echo
  echo "Servicios habilitados:"
  for i in "${!SERVICIOS[@]}"; do
    printf "%2d) %s\n" $((i+1)) "${SERVICIOS[i]}"
  done
  echo "   $(( ${#SERVICIOS[@]} + 1 ))) Salir"
  echo
  read -p "Selecciona el número del servicio a eliminar (o presiona Enter para salir): " REPLY

  # Si no se ingresa nada, salimos
  if [ -z "$REPLY" ]; then
    echo "Saliendo."
    break
  fi

  # Si la opción es inválida o no numérica
  if ! [[ "$REPLY" =~ ^[0-9]+$ ]] ; then
    echo "Por favor, ingresa un número válido."
    continue
  fi

  # Si selecciona la opción “Salir”
  if [ "$REPLY" -eq $(( ${#SERVICIOS[@]} + 1 )) ]; then
    echo "Saliendo."
    break
  fi

  # Índice válido de servicio
  if [ "$REPLY" -ge 1 ] && [ "$REPLY" -le "${#SERVICIOS[@]}" ]; then
    SVC="${SERVICIOS[$((REPLY-1))]}"
    echo
    echo ">>> Eliminando servicio: $SVC"

    systemctl stop    "$SVC" || true
    systemctl disable "$SVC" || true
    systemctl mask   "$SVC" || true

    PATH_U=$(systemctl show -p FragmentPath --value "$SVC")
    if [ -n "$PATH_U" ] && [ -f "$PATH_U" ]; then
      rm -f "$PATH_U"
      echo "Archivo de unidad eliminado: $PATH_U"
    else
      echo "No se encontró archivo de unidad para $SVC"
    fi

    systemctl daemon-reload
    echo "Servicio $SVC eliminado con éxito."
  else
    echo "Opción fuera de rango. Intenta de nuevo."
  fi
done
