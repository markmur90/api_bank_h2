#!/usr/bin/env bash
VPS_USER="markmur88"
VPS_IP="80.78.30.242"
VPS_PORT="22"
SSH_KEY="$HOME/.ssh/vps_njalla_nueva"
VPS_API_DIR="/home/$VPS_USER/api_bank_heroku"
REMOTE_STATUS_SCRIPT="$VPS_API_DIR/vps_status.sh"

STATUS_SCRIPT_CONTENT='#!/usr/bin/env bash
print_section() {
    local title="$1"
    echo
    echo "========================================"
    printf "     %s\n" "$title"
    echo "========================================"
}
print_section "1. INFORMACIÓN DEL SISTEMA"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Distribución: $NAME $VERSION"
else
    echo "Distribución: (no se detectó /etc/os-release)"
fi
echo "Kernel: $(uname -r)"
echo "Arquitectura: $(uname -m)"
echo "Hostname: $(hostname)"
echo "Fecha/Hora: $(date '\''+%Y-%m-%d %H:%M:%S'\'')"
if command -v uptime &> /dev/null; then
    echo "Uptime: $(uptime -p)"
else
    echo "Uptime: $(cat /proc/uptime | awk '\''{printf \"%.0f segundos\n\", $1}'\'')"
fi
if command -v lscpu &> /dev/null; then
    echo "CPU: $(lscpu | grep '\''Model name'\'' | sed '\''s/Model name:[[:space:]]*//;'\'')"
    echo "Cores: $(lscpu | grep '\''^CPU(s):'\'' | awk '\''{print $2}'\'')"
else
    echo "CPU: (lscpu no disponible)"
fi
print_section "2. MEMORIA (RAM/SWAP)"
if command -v free &> /dev/null; then
    free -h | awk '\''NR==1{print "            " $2, $3, $4, $5, $6, $7} NR==2{printf "RAM:        %s\t%s\t%s\n", $2, $3, $4} NR==3{printf "Swap:       %s\t%s\t%s\n", $2, $3, $4}'\''
else
    echo "free no disponible"
fi
print_section "3. ESPACIO EN DISCO"
if command -v df &> /dev/null; then
    df -h --total | awk '\''NR==1{print $0} NR>1 && $1=="total" {print "\nTOTAL: "$2"\t"$3"\t"$4"\t"$5; exit} NR>1 && $1!~/tmpfs|udev/ {printf "%-20s %6s %6s %6s %4s %s\n", $1, $2, $3, $4, $5, $6}'\''
else
    echo "df no disponible"
fi
print_section "4. SERVICIOS (systemd)"
if command -v systemctl &> /dev/null; then
    echo "Estado de servicios habilitados (ACTIVE/INACTIVE):"
    systemctl list-unit-files --type=service --no-pager | awk '\''$2 ~ /enabled|disabled/ { printf "%-50s %s\n", $1, $2 }'\''
    echo
    echo "Servicios activos actualmente:"
    systemctl list-units --type=service --state=running --no-pager | awk '\''NR>1 { printf "%-40s %s\n", $1, $4 }'\''
else
    echo "systemctl no disponible"
fi
print_section "5. PUERTOS ABIERTOS Y PROCESOS ASOCIADOS"
if command -v ss &> /dev/null; then
    echo "Protocolo  Puerto     Estado      Proceso/Programa"
    ss -tulpn 2>/dev/null | awk '\''NR>1 { proto=$1; split($5, a, "[:]"); port=a[length(a)]; state=$2; proc=$7; printf "%-8s %-8s %-10s %s\n", proto, port, state, proc }'\''
elif command -v netstat &> /dev/null; then
    echo "Protocolo  Puerto     Estado      Proceso/Programa"
    netstat -tulpn 2>/dev/null | awk '\''NR>2 { proto=$1; split($4, a, "[:]"); port=a[length(a)]; state=$6; proc=$7; printf "%-8s %-8s %-10s %s\n", proto, port, state, proc }'\''
else
    echo "ss/netstat no disponible"
fi
echo
echo "Informe generado el $(date '\''+%Y-%m-%d %H:%M:%S'\'')."
echo "¡Listo! 👍"'

# 1. Crear carpeta remota (si no existe) y copiar script
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "mkdir -p \"$VPS_API_DIR\""
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "cat > \"$REMOTE_STATUS_SCRIPT\" << 'EOF'
$STATUS_SCRIPT_CONTENT
EOF"

# 2. Dar permisos de ejecución
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "chmod +x \"$REMOTE_STATUS_SCRIPT\""

# 3. Ejecutar el script remoto con sudo y mostrar salida localmente
ssh -i "$SSH_KEY" -p "$VPS_PORT" "$VPS_USER@$VPS_IP" "sudo \"$REMOTE_STATUS_SCRIPT\""
