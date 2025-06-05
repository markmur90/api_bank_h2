#!/usr/bin/env bash
# detener_gestores.sh

# Buscar procesos que ejecuten gestor_tareas_*.sh
echo "🔍 Buscando scripts activos tipo gestor_tareas_*.sh..."

mapfile -t resultados < <(ps -eo pid,cmd --sort=start_time | grep "[g]estor_tareas_.*\.sh")

if [ ${#resultados[@]} -eq 0 ]; then
    echo "✅ No hay gestores activos."
    exit 0
fi

# Preparar lista para Zenity
zenity_args=()
for linea in "${resultados[@]}"; do
    PID=$(echo "$linea" | awk '{print $1}')
    CMD=$(echo "$linea" | cut -d' ' -f2-)
    zenity_args+=(FALSE "$PID :: $CMD")
done

# Mostrar selección
seleccion=$(zenity --list \
                   --checklist \
                   --title="🛑 Gestores en ejecución" \
                   --text="Selecciona los procesos que deseas detener:" \
                   --column="" --column="Proceso" \
                   "${zenity_args[@]}" \
                   --width=900 --height=500 \
                   --ok-label="Detener seleccionados" \
                   --cancel-label="Salir")

[ $? -ne 0 ] && echo "❎ Cancelado." && exit 1
[ -z "$seleccion" ] && echo "⚠ No se seleccionó ningún proceso." && exit 0

# Extraer PIDs y matar
IFS="|" read -r -a seleccionados <<< "$seleccion"

for item in "${seleccionados[@]}"; do
    PID=$(echo "$item" | cut -d' ' -f1)
    kill "$PID" && echo "🗑 Detenido PID $PID"
done

echo "✅ Listo. Procesos finalizados."
