#!/usr/bin/env bash
#
# vps_status.sh – Informe completo de estado de VPS:
#   - Datos del sistema (kernel, distro, uptime, hostname)
#   - Uso de CPU y memoria
#   - Uso de disco
#   - Servicios systemd y su estado
#   - Puertos abiertos (TCP/UDP) y procesos asociados
#
# 2025 © Informe generado automáticamente

# ------------- Funciones auxiliares ------------- #

# Imprime línea separadora con título centrado
print_section() {
    local title="$1"
    echo
    echo "========================================"
    printf "     %s\n" "$title"
    echo "========================================"
}

# ------------- 1. DATOS DEL SISTEMA ------------- #
print_section "1. INFORMACIÓN DEL SISTEMA"

# Distribución / Kernel
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribución: $NAME $VERSION"
else
    echo "Distribución: (no se detectó /etc/os-release)"
fi
echo "Kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"

# Hostname y fecha/hora actual
echo "Hostname: $(hostname)"
echo "Fecha/Hora: $(date '+%Y-%m-%d %H:%M:%S')"

# Uptime (tiempo de actividad)
if command -v uptime &> /dev/null; then
    echo "Uptime: $(uptime -p)"
else
    echo "Uptime: $(cat /proc/uptime | awk '{printf "%.0f segundos\n", $1}')"
fi

# Información CPU
if command -v lscpu &> /dev/null; then
    echo "CPU: $(lscpu | grep 'Model name' | sed 's/Model name:[[:space:]]*//')"
    echo "Cores: $(lscpu | grep '^CPU(s):' | awk '{print $2}')"
else
    echo "CPU: (lscpu no disponible)"
fi

# ------------- 2. USO DE MEMORIA Y SWAP ------------- #
print_section "2. MEMORIA (RAM/SWAP)"

if command -v free &> /dev/null; then
    free -h | awk 'NR==1{print "            " $2, $3, $4, $5, $6, $7} NR==2{printf "RAM:        %s\t%s\t%s\n", $2, $3, $4} NR==3{printf "Swap:       %s\t%s\t%s\n", $2, $3, $4}'
else
    echo "free no disponible"
fi

# ------------- 3. USO DE DISCO ------------- #
print_section "3. ESPACIO EN DISCO"

if command -v df &> /dev/null; then
    df -h --total | awk 'NR==1{print $0} NR>1 && $1=="total" {print "\nTOTAL: "$2"\t"$3"\t"$4"\t"$5; exit} NR>1 && $1!~/tmpfs|udev/ {printf "%-20s %6s %6s %6s %4s %s\n", $1, $2, $3, $4, $5, $6}'
else
    echo "df no disponible"
fi

# ------------- 4. SERVICIOS SYSTEMD ------------- #
print_section "4. SERVICIOS (systemd)"

if command -v systemctl &> /dev/null; then
    # Listar servicios instalados con su estado
    echo "Estado de servicios habilitados (ACTIVE/INACTIVE):"
    systemctl list-unit-files --type=service --no-pager | awk '$2 ~ /enabled|disabled/ { printf "%-50s %s\n", $1, $2 }'
    echo
    echo "Servicios activos actualmente:"
    systemctl list-units --type=service --state=running --no-pager | awk 'NR>1 { printf "%-40s %s\n", $1, $4 }'
else
    echo "systemctl no disponible"
fi

# ------------- 5. PUERTOS ABIERTOS ------------- #
print_section "5. PUERTOS ABIERTOS Y PROCESOS ASOCIADOS"

# Preferir ss; si no existe, usar netstat
if command -v ss &> /dev/null; then
    echo "Protocolo  Puerto     Estado      Proceso/Programa"
    ss -tulpn 2>/dev/null | awk 'NR>1 { proto=$1; split($5, a, ":"); port=a[length(a)]; state=$2; proc=$7; printf "%-8s %-8s %-10s %s\n", proto, port, state, proc }'
elif command -v netstat &> /dev/null; then
    echo "Protocolo  Puerto     Estado      Proceso/Programa"
    netstat -tulpn 2>/dev/null | awk 'NR>2 { proto=$1; split($4, a, ":"); port=a[length(a)]; state=$6; proc=$7; printf "%-8s %-8s %-10s %s\n", proto, port, state, proc }'
else
    echo "ss/netstat no disponible"
fi

# ------------- FIN DEL INFORME ------------- #
echo
echo "Informe generado el $(date '+%Y-%m-%d %H:%M:%S')."
echo "¡Listo! 👍"
