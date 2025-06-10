# ╔═══════════════════════════════════════════╗
# ║     ALIAS RESUMIDOS + MENÚ TUI PARA api_bank_h2          ║
# ║  Ejecutar despliegues automatizados y personalizados        ║
# ║  Usa `deploy_menu` para elegir visualmente con FZF         ║
# ║  Usa `d_help` para ver ejemplos detallados con flags       ║
# ╚═══════════════════════════════════════════╝

clear

alias d_all="./01_full.sh -a"
alias d_step="./01_full.sh -s"
alias d_debug="./01_full.sh -d -s"
alias d_noback="./01_full.sh -L -r -Z"
alias d_light="./01_full.sh -H -G"
alias d_nosu="./01_full.sh -V -U -r"
alias d_clean="./01_full.sh -S -D"
alias d_stable="./01_full.sh -P -M"
alias d_fast="./01_full.sh -Y -C"
alias d_nomig="./01_full.sh -Q -I -Z"
alias d_nopem="./01_full.sh -p -U -r"
alias d_hotfix="./01_full.sh -H -G -p -U -V"
alias d_nogui="./01_full.sh -r -G -M"
alias d_migonly="./01_full.sh -s -Q -I -C"
alias d_diag="./01_full.sh -s -D -P -G"
alias d_noload="./01_full.sh -l"
alias d_pure="./01_full.sh -L -l -p -r"
alias d_strict="./01_full.sh -C -Z -M -V -U"
alias d_safe="./01_full.sh -H -G -D -P -Y -M -C -V"
alias d_short="./01_full.sh -L -U -V"
alias d_review="./01_full.sh -U -V"
alias d_fastlight="./01_full.sh -L -U"
alias d_fast="./01_full.sh -L -U -V"
alias d_heroless="./01_full.sh -H -U -V"
alias d_reload="./01_full.sh -L -U -I"
alias d_localzip="./01_full.sh -Z -L -U -V"
alias d_testrun="./01_full.sh -U -r"
alias d_baremetal="./01_full.sh -Z -C -U -V"
alias d_rebuild="./01_full.sh -Q -I -U -V"
alias d_trimmed="./01_full.sh -L -U -V -r"
alias d_noufw="./01_full.sh -x"

alias d_njalla_first="./01_full.sh -H -Z -C -M -V -U -P"
alias d_njalla_setup="ssh -i $SSH_KEY root@$VPS_IP 'bash -s' < scripts/vps_instalar_dependencias.sh"
alias d_njalla_sync="rsync -avz -e \"ssh -i $SSH_KEY\" $PROJECT_ROOT/ $VPS_USER@$VPS_IP:$VPS_API_DIR/"

alias d_resetdb="heroku pg:reset DATABASE_URL --confirm $(heroku apps:info -s | grep web_url | cut -d= -f2 | cut -d. -f1)"

alias d_run_local="./01_full.sh -H -G -U -P --DEPLOY_VPS=false"
alias d_run_local_heroku="./01_full.sh -G -P"
alias d_run_local_vps="./01_full.sh -H -P"
alias d_run_all="./01_full.sh -a"
alias d_all="./01_full.sh -a"


# === CLAVES SSH ===
ssh-add ~/.ssh/id_ed25519 && ssh-add ~/.ssh/vps_njalla_nueva

# === ACCESOS DIRECTOS AL PROYECTO ===

alias api='cd "$HOME/Documentos/GitHub/api_bank_h2" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear'
alias BKapi='cd "$HOME/Documentos/GitHub/api_bank_h2_BK" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear && code .'
alias api_heroku='cd "$HOME/Documentos/GitHub/api_bank_heroku" && source "$HOME/Documentos/Entorno/envAPP/bin/activate" && clear'
alias update='sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y'
alias monero='bash /opt/monero-gui/monero/monero-wallet-gui'


alias d_help='bash ./01_full.sh --help'
alias d_step='bash ./01_full.sh -s'
alias d_all='bash ./01_full.sh -a'
alias d_debug='bash ./01_full.sh -d'
alias d_menu='bash ./01_full.sh --menu'
alias d_status='bash ./scripts/diagnostico_entorno.sh'

# 🌐 Local (versión completa y versión corta)
unalias ad_local 2>/dev/null
ad_local() {cd "$HOME/Documentos/GitHub/api_bank_h2" && clear "$@"}

unalias ad_heroku 2>/dev/null
ad_heroku() {cd "$HOME/Documentos/GitHub/api_bank_heroku" && clear "$@"}

unalias d_env 2>/dev/null
d_env() {source "$HOME/Documentos/Entorno/envAPP/bin/activate" "$@"}

unalias d_mig 2>/dev/null
d_mig() {python3 manage.py makemigrations && python3 manage.py migrate && python3 manage.py collectstatic --noinput && clear "$@"}

unalias d_local 2>/dev/null
d_local() {ad_local && d_env && bash ./01_full.sh --env=local -Z -C -S -Q -I -l && code . "$@"}

unalias d_heroku 2>/dev/null
d_heroku() {ad_local && d_env && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B && ad_heroku "$@"}

unalias d_njalla 2>/dev/null
d_njalla() {ad_local && d_env && bash ./01_full.sh --env=production -Z -C -S -Q -I -l -H -B -v && ad_heroku && code . "$@"}

unalias d_pgm 2>/dev/null
d_pgm() {d_env && bash ./01_full.sh -Q -I -l "$@"}

unalias d_hek 2>/dev/null
d_hek() {d_env && bash ./01_full.sh -B -H "$@"}

unalias d_back 2>/dev/null
d_back() {d_env && bash ./01_full.sh -C -Z "$@"}

unalias d_sys 2>/dev/null
d_sys() {d_env && bash ./01_full.sh -Y -P -D -M -x "$@"}

unalias d_cep 2>/dev/null
d_cep() {d_env && bash ./01_full.sh -p -E "$@"}

unalias d_vps 2>/dev/null
d_vps() {d_env && bash ./01_full.sh -v "$@"}

deploy_menu() {
    local options=(
        "d_all             ➤ -a                                ➤ Todo automático (producción completa)"
        "d_step            ➤ -s                                 ➤ Modo paso a paso con confirmaciones"
        "d_debug           ➤ -d -s                              ➤ Debug + paso a paso con diagnóstico"
        "d_noback          ➤ -L -r -Z                        ➤ Con backups, carga web y ZIP"
        "d_light           ➤ -H -G                           ➤ Con Heroku y Gunicorn (local ligero)"
        "d_nosu            ➤ -V -U -r                        ➤ Con superusuario, verificación y navegador"
        "d_clean           ➤ -S -D                           ➤ Con sync y Docker"
        "d_stable          ➤ -P -M                           ➤ Con cerrar puertos y cambiar MAC"
        "d_fast            ➤ -Y -C                           ➤ Con actualizar sistema y limpiar respaldos"
        "d_nomig           ➤ -Q -I -Z                        ➤ Con PGSQL, migraciones y ZIP"
        "d_nopem           ➤ -p -U -r                        ➤ Con PEM, superusuario y navegador"
        "d_hotfix          ➤ -H -G -p -U -V                  ➤ Hotfix Con deploy, claves y verificación"
        "d_nogui           ➤ -r -G -M                        ➤ Con GUI, Gunicorn y MAC"
        "d_migonly         ➤ -s -Q -I -C                        ➤ Solo migraciones, Con PGSQL y limpieza"
        "d_diag            ➤ -s -D -P -G                        ➤ Diagnóstico: Docker, puertos, Gunicorn"
        "d_noload          ➤ -l                              ➤ Con cargar JSON local"
        "d_pure            ➤ -L -l -p -r                     ➤ Producción pura Con JSON, PEM y navegador"
        "d_strict          ➤ -C -Z -M -V -U                  ➤ Producción estricta, Con residuos"
        "d_local           ➤ -p -U -I -Q -H -G               ➤ Solo entorno local, Con deploy externo"
        "d_safe            ➤ -H -G -D -P -Y -M -C -V         ➤ Producción aislada Con conexiones"
        "d_short           ➤ -L -U -V                        ➤ Rápido Con carga, usuario y validación"
        "d_review          ➤ -U -V                           ➤ Validación Con superusuario y carga"
        "d_fastlight       ➤ -L -U                           ➤ Con backups y superusuario"
        "d_fast            ➤ -L -U -V                        ➤ Con backups y superusuario y validación"
        "d_heroless        ➤ -H -U -V                        ➤ Con Heroku, Con usuario, Con validaciones"
        "d_reload          ➤ -L -U -I                        ➤ Con carga, Con usuario, con migración"
        "d_localzip        ➤ -Z -L -U -V                     ➤ Con zip, Con JSON, Con validación"
        "d_testrun         ➤ -U -r                           ➤ Modo test Con navegador y validación"
        "d_baremetal       ➤ -Z -C -U -V                     ➤ Despliegue limpio Con backups"
        "d_rebuild         ➤ -Q -I -U -V                     ➤ Reconstrucción Con validaciones finales"
        "d_trimmed         ➤ -L -U -V -r                     ➤ Rápido, Con carga, web y validaciones"
        "d_noufw           ➤ -x                              ➤ Todo Con UFW"

        # 🔧 Alias personalizados
        "d_njalla_first     ➤ -H -Z -C -M -V -U -P           ➤ Primer despliegue completo al VPS (producción)"
        "d_njalla_setup     ➤ ssh <script>                      ➤ Instala dependencias completas en el VPS"
        "d_njalla_sync      ➤ rsync local → VPS                 ➤ Sincroniza archivos locales al VPS"
        "d_resetdb          ➤ heroku pg:reset                   ➤ Reinicia completamente la base en Heroku"
        "d_run_local        ➤ -H -G -U -P -v                 ➤ Corre solo en local con todo"
        "d_run_local_heroku ➤ -G -P -v                       ➤ Corre en local + Heroku"
        "d_run_local_vps    ➤ -H -P                         ➤ Corre en local + VPS"
        "d_run_all          ➤                               ➤ Corre en local + VPS + Heroku"
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



# Autocompletado para todos los alias d_*
_d_aliases_autocomplete() {
    local cur opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(compgen alias | grep '^d_')
    COMPREPLY=( $(compgen -r "${opts}" -- "${cur}") )
}

autoload -Uz compinit && compinit
compdef _d_aliases_autocomplete d_*

