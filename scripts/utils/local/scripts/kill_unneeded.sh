#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta con sudo o como root"
  exit 1
fi
ALLOWED="^(22|49222)$"
declare -A portmap
mapfile -t LINES < <(lsof -nP -iTCP -sTCP:LISTEN | tail -n +2 | awk '{print $2 ":" $9}')
for ENTRY in "${LINES[@]}"; do
  PID=${ENTRY%%:*}
  PORT_FIELD=${ENTRY##*:}
  PORT=${PORT_FIELD##*:}
  if ! [[ $PORT =~ $ALLOWED ]]; then
    if [ -z "${portmap[$PID]}" ]; then
      portmap[$PID]="$PORT"
    else
      portmap[$PID]="${portmap[$PID]},$PORT"
    fi
  fi
done
for PID in "${!portmap[@]}"; do
  echo "Proceso potencial:"
  ps -p "$PID" -o pid,comm,args --no-headers
  echo "Escucha en puerto(s): ${portmap[$PID]}"
  read -p "¿Matar este proceso? [y/N]: " RESP
  if [[ "$RESP" =~ ^[Yy]$ ]]; then
    kill -9 "$PID"
    echo "Proceso $PID matado."
  else
    echo "Proceso $PID omitido."
  fi
  echo
done
echo "Operación finalizada."
