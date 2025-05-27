# ╔═════════════════════════════════════════════════════════════╗
# ║     ALIAS RESUMIDOS + MENÚ TUI PARA api_bank_h2          ║
# ║  Ejecutar despliegues automatizados y personalizados        ║
# ║  Usa `deploy_menu` para elegir visualmente con FZF         ║
# ║  Usa `d_help` para ver ejemplos detallados con flags       ║
# ╚═════════════════════════════════════════════════════════════╝

clear

# === PRIMER DESPLIEGUE Y VPS ===
alias d_njalla_first='(     ssh -i $SSH_KEY root@$VPS_IP "bash -s" < scripts/vps_instalar_dependencias.sh &&     ./01_full.sh -a -H -Z -C -M -V -U -P )'
alias d_njalla_setup="ssh -i \$SSH_KEY root@\$VPS_IP 'bash -s' < scripts/vps_instalar_dependencias.sh"
alias d_njalla_sync="rsync -avz -e \"ssh -i \$SSH_KEY\" \$PROJECT_ROOT/ \$VPS_USER@\$VPS_IP:\$VPS_API_DIR/"

# === TEST Y SSL ===
alias d_test_vps='ssh -i $SSH_KEY $VPS_USER@$VPS_IP bash -s <<EOF
echo -e "\033[1;34m🔍 Verificando VPS: \$HOSTNAME\033[0m"
echo -e "\n🔐 Probar acceso sudo:"
if sudo -n true 2>/dev/null; then
    echo -e "\033[1;32m✅ Acceso sudo confirmado\033[0m"
else
    echo -e "\033[1;31m❌ No tienes acceso sudo sin contraseña\033[0m"
fi
echo -e "\n🌐 Verificando conectividad externa:"
ping -c 2 1.1.1.1 >/dev/null && echo -e "\033[1;32m✅ Internet OK\033[0m" || echo -e "\033[1;31m❌ Sin conectividad\033[0m"
echo -e "\n📦 Estado de servicios principales:"
for service in nginx postgresql; do
    echo -n "🔧 $service: "
    systemctl is-active --quiet \$service && echo -e "\033[1;32mactivo\033[0m" || echo -e "\033[1;31minactivo\033[0m"
done
echo -e "\n📂 Espacio en disco relevante:"
df -h /home / | grep -v tmpfs
echo -e "\n🧠 Memoria RAM:"
free -h
echo -e "\n✅ Revisión VPS finalizada."
EOF'

alias d_test_certbot='ssh -i $SSH_KEY $VPS_USER@$VPS_IP bash -s <<EOF
echo -e "\033[1;34m🔐 Verificando estado de Certbot y certificados SSL...\033[0m"
# Comprobar instalación de certbot
if ! command -v certbot &>/dev/null; then
    echo -e "\033[1;31m❌ Certbot no está instalado en el VPS.\033[0m"
    exit 1
else
    echo -e "\033[1;32m✅ Certbot está instalado.\033[0m"
fi
# Comprobar certificados para el dominio
DOMINIO=\"apih.coretransapi.com\"
CERT_PATH=\"/etc/letsencrypt/live/\$DOMINIO/fullchain.pem\"
if [[ -f \"\$CERT_PATH\" ]]; then
    echo -e \"\n📜 Certificado encontrado para \$DOMINIO:\"
    end_date=\$(openssl x509 -in \"\$CERT_PATH\" -noout -enddate | cut -d= -f2)
    echo -e \"  🔐 Fecha de expiración: \033[1;33m\$end_date\033[0m\"
    # Comprobar si expira pronto
    days_left=\$(openssl x509 -in \"\$CERT_PATH\" -noout -checkend \$(( 15 * 86400 )) && echo OK || echo EXPIRED)
    if [[ \$days_left == \"OK\" ]]; then
        echo -e \"  \033[1;32m✅ El certificado está vigente por al menos 15 días.\033[0m\"
    else
        echo -e \"  \033[1;31m⚠️ El certificado expira en menos de 15 días. Considera renovarlo.\033[0m\"
    fi
else
    echo -e \"\033[1;31m❌ No se encontró certificado para \$DOMINIO en \$CERT_PATH\033[0m\"
fi
EOF'

alias d_certbot_renew='ssh -i $SSH_KEY $VPS_USER@$VPS_IP bash -s <<EOF
echo -e "\033[1;34m🔄 Ejecutando renovación de certificados SSL con Certbot...\033[0m"
if ! command -v certbot &>/dev/null; then
    echo -e "\033[1;31m❌ Certbot no está instalado. Abortando.\033[0m"
    exit 1
fi
output=\$(sudo certbot renew --quiet --deploy-hook \"echo __RESTART_NGINX__\")
echo "\$output"
if echo "\$output" | grep -q \"__RESTART_NGINX__\"; then
    echo -e "\033[1;36m🔁 Certificado renovado, reiniciando Nginx...\033[0m"
    sudo systemctl reload nginx
    echo -e "\033[1;32m✅ Certificados renovados y Nginx recargado.\033[0m"
else
    echo -e "\033[1;33mℹ️ No se detectaron certificados renovados. No se reinició Nginx.\033[0m"
fi
EOF'

# === BASE DE DATOS ===
alias d_resetdb="heroku pg:reset DATABASE_URL --confirm \$(heroku apps:info -s | grep web_url | cut -d= -f2 | cut -d. -f1)"

# === EJECUCIONES COMBINADAS ===
alias d_run_local="./01_full.sh -a -H -G -U -P -v"
alias d_run_local_heroku="./01_full.sh -a -G -P -v"
alias d_run_local_vps="./01_full.sh -a -H -P -H"
alias d_run_all="./01_full.sh -a"

# === TRADICIONALES Y UTILITARIOS ===
alias d_all="./01_full.sh -a"
alias d_step="./01_full.sh -s"
alias d_debug="./01_full.sh -d -s"
alias d_light="./01_full.sh -a -H -G"
alias d_local="./01_full.sh -a -p -U -I -Q -H -G"
alias d_help='sed -n "/EJEMPLOS COMBINADOS/,/FIN: EJEMPLOS COMBINADOS/p" ~/Documentos/GitHub/api_bank_h2/01_full.sh | less -R'

# === MENÚ INTERACTIVO ===
deploy_menu() {
    local options=(
        "d_njalla_first      ➤ -a -H -Z -C -M -V -U -P        ➤ Primer despliegue completo al VPS (producción)"
        "d_njalla_setup      ➤ ssh <script>                  ➤ Instala dependencias completas en el VPS"
        "d_njalla_sync       ➤ rsync local → VPS             ➤ Sincroniza archivos locales al VPS"
        "d_test_vps          ➤ test → VPS                    ➤ Verifica sudo, conectividad, servicios, RAM"
        "d_test_certbot      ➤ test certbot → VPS            ➤ Verifica estado de Certbot y certificados SSL"
        "d_certbot_renew     ➤ renovar certbot → VPS         ➤ Ejecuta renovación automática de certificados SSL"
        "d_resetdb           ➤ heroku pg:reset               ➤ Reinicia completamente la base en Heroku"

        "d_run_local         ➤ -a -H -G -U -P -v              ➤ Corre solo en local (sin VPS)"
        "d_run_local_heroku  ➤ -a -G -P -v                    ➤ Corre en local + Heroku (sin VPS)"
        "d_run_local_vps     ➤ -a -H -P -H                    ➤ Corre en local + VPS (sin Heroku)"
        "d_run_all           ➤ -a                             ➤ Corre local + Heroku + VPS"

        "d_all               ➤ -a                             ➤ Todo automático (producción completa)"
        "d_step              ➤ -s                             ➤ Modo paso a paso con confirmaciones"
        "d_debug             ➤ -d -s                          ➤ Debug + paso a paso con diagnóstico"
        "d_light             ➤ -a -H -G                       ➤ Sin Heroku ni Gunicorn (local ligero)"
        "d_local             ➤ -a -p -U -I -Q -H -G           ➤ Solo entorno local sin deploy externo"
        "d_help              ➤                                ➤ Ver ejemplos combinados directamente"
    )

    local choice
    choice=$(printf "%s\n" "${options[@]}" | fzf --prompt="▶ Selecciona despliegue:" --height=40% --border --reverse --no-info)
    local cmd
    cmd=$(echo "$choice" | awk '{print $1}')
    if [[ -n "$cmd" ]]; then
        echo -e "\n🔹 Ejecutando: \033[1;36m$cmd\033[0m"
        actual_cmd=$(alias "$cmd" | awk -F"'" '{print $2}')
        echo -e "\033[1;33m➡️ Comando real:\033[0m $actual_cmd"
        echo -e "\n\033[1;32m[LOG] Salida de ejecución:\033[0m\n"
        eval "$actual_cmd"
    else
        echo "❌ Cancelado."
    fi
}

# === AUTOCOMPLETADO ===
_d_aliases_autocomplete() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(compgen -A alias | grep '^d_')
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
}

autoload -Uz compinit && compinit
compdef _d_aliases_autocomplete d_*