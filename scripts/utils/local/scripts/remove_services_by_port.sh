#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Ejecuta como root o con sudo"
  exit 1
fi

# Recoge todos los servicios habilitados, excluyendo plantillas (@)
mapfile -t ALL_SERV < <(
  systemctl list-unit-files --type=service \
    | awk '$2=="enabled"{print $1}' \
    | grep -v "@"
)

declare -a SVC PORTS PIDS

# Construye las listas de servicios que están escuchando puertos TCP
for svc in "${ALL_SERV[@]}"; do
  pid=$(systemctl show -p MainPID --value "$svc")
  if [[ "$pid" =~ ^[0-9]+$ ]] && [ "$pid" -ne 0 ]; then
    prts=$(lsof -nP -a -p "$pid" -iTCP -sTCP:LISTEN 2>/dev/null \
      | awk 'NR>1{gsub(/.*:/,"",$9); print $9}' \
      | sort -u \
      | paste -sd, -)
    if [ -n "$prts" ]; then
      SVC+=("$svc")
      PIDS+=("$pid")
      PORTS+=("$prts")
    fi
  fi
done

if [ "${#SVC[@]}" -eq 0 ]; then
  echo "No hay servicios habilitados escuchando puertos TCP."
  exit 0
fi

# Menú interactivo para eliminar
while :; do
  echo
  for i in "${!SVC[@]}"; do
    printf "%2d) %s — puertos: %s — pid: %s\n" \
      $((i+1)) "${SVC[i]}" "${PORTS[i]}" "${PIDS[i]}"
  done
  idx=$(( ${#SVC[@]} + 1 ))
  printf "   %d) Salir\n" "$idx"

  read -p "Selecciona número para eliminar (Enter para salir): " REPLY

  # Salir si vacío o selecciona “Salir”
  if [ -z "$REPLY" ] || ! [[ "$REPLY" =~ ^[0-9]+$ ]] || [ "$REPLY" -eq "$idx" ]; then
    echo "Saliendo."
    break
  fi

  # Validación de rango y eliminación
  if [ "$REPLY" -ge 1 ] && [ "$REPLY" -le "${#SVC[@]}" ]; then
    svc="${SVC[$((REPLY-1))]}"
    pid="${PIDS[$((REPLY-1))]}"

    echo ">>> Eliminando servicio $svc (pid $pid)"
    systemctl stop    "$svc" || true
    systemctl disable "$svc" || true
    systemctl mask   "$svc" || true

    unit_path=$(systemctl show -p FragmentPath --value "$svc")
    if [ -n "$unit_path" ] && [ -f "$unit_path" ]; then
      rm -f "$unit_path"
      echo "Archivo de unidad eliminado: $unit_path"
    fi

    systemctl daemon-reload
    echo "Servicio $svc eliminado con éxito."

    # Elimina de los arrays
    unset 'SVC[REPLY-1]' 'PIDS[REPLY-1]' 'PORTS[REPLY-1]'
    SVC=("${SVC[@]}"); PIDS=("${PIDS[@]}"); PORTS=("${PORTS[@]}")

    if [ "${#SVC[@]}" -eq 0 ]; then
      echo "No quedan servicios en la lista."
      break
    fi
  else
    echo "Opción fuera de rango."
  fi
done
