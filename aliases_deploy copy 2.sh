# ╔═════════════════════════════════════════════════════════════╗
# ║     ALIAS RESUMIDOS + MENÚ TUI PARA api_bank_heroku          ║
# ║  Ejecutar despliegues automatizados y personalizados        ║
# ║  Usa `deploy_menu` para elegir visualmente con FZF         ║
# ║  Usa `d_help` para ver ejemplos detallados con flags       ║
# ╚═════════════════════════════════════════════════════════════╝

clear

alias d_all="./01_full.sh -a"
alias d_step="./01_full.sh -s"
alias d_debug="./01_full.sh -d -s"
alias d_noback="./01_full.sh -a -L -w -Z"
alias d_light="./01_full.sh -a -H -G"
alias d_nosu="./01_full.sh -a -V -U -w"
alias d_clean="./01_full.sh -a -S -D"
alias d_stable="./01_full.sh -a -P -M"
alias d_fast="./01_full.sh -a -Y -C"
alias d_nomig="./01_full.sh -a -Q -I -Z"
alias d_nopem="./01_full.sh -a -p -U -w"
alias d_hotfix="./01_full.sh -a -H -G -p -U -V"
alias d_nogui="./01_full.sh -a -w -G -M"
alias d_migonly="./01_full.sh -s -Q -I -C"
alias d_diag="./01_full.sh -s -D -P -G"
alias d_noload="./01_full.sh -a -l"
alias d_pure="./01_full.sh -a -L -l -p -w"
alias d_strict="./01_full.sh -a -C -Z -M -V -U"
alias d_local="./01_full.sh -a -p -U -I -Q -H -G"
alias d_safe="./01_full.sh -a -H -G -D -P -Y -M -C -V"
alias d_short="./01_full.sh -a -L -U -V"
alias d_review="./01_full.sh -a -U -V"
alias d_fastlight="./01_full.sh -a -L -U"
alias d_fast="./01_full.sh -a -L -U -V"
alias d_heroless="./01_full.sh -a -H -U -V"
alias d_reload="./01_full.sh -a -L -U -I"
alias d_localzip="./01_full.sh -a -Z -L -U -V"
alias d_testrun="./01_full.sh -a -U -w"
alias d_baremetal="./01_full.sh -a -Z -C -U -V"
alias d_rebuild="./01_full.sh -a -Q -I -U -V"
alias d_trimmed="./01_full.sh -a -L -U -V -w"
alias d_noufw="./01_full.sh -a -x"

alias d_njalla_first="./01_full.sh -a -H -Z -C -M -V -U -P"
alias d_njalla_setup="ssh -i $SSH_KEY root@$VPS_IP 'bash -s' < scripts/vps_instalar_dependencias.sh"
alias d_njalla_sync="rsync -avz -e \"ssh -i $SSH_KEY\" $PROJECT_ROOT/ $VPS_USER@$VPS_IP:$VPS_API_DIR/"

alias d_resetdb="heroku pg:reset DATABASE_URL --confirm $(heroku apps:info -s | grep web_url | cut -d= -f2 | cut -d. -f1)"

alias d_run_local="./01_full.sh -a -H -G -U -P --DEPLOY_VPS=false"
alias d_run_local_heroku="./01_full.sh -a -G -P"
alias d_run_local_vps="./01_full.sh -a -H -P"
alias d_run_all="./01_full.sh -a"
alias d_all="./01_full.sh -a"

alias d_step="./01_full.sh -s"
alias d_debug="./01_full.sh -d -s"
alias d_local="./01_full.sh -a -p -U -I -Q -H -G"
alias d_light="./01_full.sh -a -H -G"
alias d_fast="./01_full.sh -a -L -U -V"
alias d_help='sed -n "/EJEMPLOS COMBINADOS/,/FIN: EJEMPLOS COMBINADOS/p" ~/Documentos/GitHub/api_bank_heroku/01_full.sh | less -R'


deploy_menu() {
    local options=(
        "d_all             ➤ -a                                 ➤ Todo automático (producción completa)"
        "d_step            ➤ -s                                 ➤ Modo paso a paso con confirmaciones"
        "d_debug           ➤ -d -s                              ➤ Debug + paso a paso con diagnóstico"
        "d_noback          ➤ -a -L -w -Z                        ➤ Sin backups, carga web ni ZIP"
        "d_light           ➤ -a -H -G                           ➤ Sin Heroku ni Gunicorn (local ligero)"
        "d_nosu            ➤ -a -V -U -w                        ➤ Sin superusuario, verificación ni navegador"
        "d_clean           ➤ -a -S -D                           ➤ Sin sync ni Docker"
        "d_stable          ➤ -a -P -M                           ➤ Sin cerrar puertos ni cambiar MAC"
        "d_fast            ➤ -a -Y -C                           ➤ Sin actualizar sistema ni limpiar respaldos"
        "d_nomig           ➤ -a -Q -I -Z                        ➤ Sin PGSQL, migraciones ni ZIP"
        "d_nopem           ➤ -a -p -U -w                        ➤ Sin PEM, superusuario ni navegador"
        "d_hotfix          ➤ -a -H -G -p -U -V                  ➤ Hotfix sin deploy, claves ni verificación"
        "d_nogui           ➤ -a -w -G -M                        ➤ Sin GUI, Gunicorn ni MAC"
        "d_migonly         ➤ -s -Q -I -C                        ➤ Solo migraciones, sin PGSQL ni limpieza"
        "d_diag            ➤ -s -D -P -G                        ➤ Diagnóstico: Docker, puertos, Gunicorn"
        "d_noload          ➤ -a -l                              ➤ Sin cargar JSON local"
        "d_pure            ➤ -a -L -l -p -w                     ➤ Producción pura sin JSON, PEM ni navegador"
        "d_strict          ➤ -a -C -Z -M -V -U                  ➤ Producción estricta, sin residuos"
        "d_local           ➤ -a -p -U -I -Q -H -G               ➤ Solo entorno local, sin deploy externo"
        "d_safe            ➤ -a -H -G -D -P -Y -M -C -V         ➤ Producción aislada sin conexiones"
        "d_short           ➤ -a -L -U -V                        ➤ Rápido sin carga, usuario ni validación"
        "d_review          ➤ -a -U -V                           ➤ Validación sin superusuario ni carga"
        "d_fastlight       ➤ -a -L -U                           ➤ Sin backups ni superusuario"
        "d_fast            ➤ -a -L -U -V                        ➤ Sin backups ni superusuario ni validación"
        "d_heroless        ➤ -a -H -U -V                        ➤ Sin Heroku, sin usuario, sin validaciones"
        "d_reload          ➤ -a -L -U -I                        ➤ Sin carga, sin usuario, con migración"
        "d_localzip        ➤ -a -Z -L -U -V                     ➤ Sin zip, sin JSON, sin validación"
        "d_testrun         ➤ -a -U -w                           ➤ Modo test sin navegador ni validación"
        "d_baremetal       ➤ -a -Z -C -U -V                     ➤ Despliegue limpio sin backups"
        "d_rebuild         ➤ -a -Q -I -U -V                     ➤ Reconstrucción sin validaciones finales"
        "d_trimmed         ➤ -a -L -U -V -w                     ➤ Rápido, sin carga, web ni validaciones"
        "d_noufw           ➤ -a -x                              ➤ Todo sin UFW"

        # 🔧 Alias personalizados
        "d_njalla_first     ➤ -a -H -Z -C -M -V -U -P           ➤ Primer despliegue completo al VPS (producción)"
        "d_njalla_setup     ➤ ssh <script>                      ➤ Instala dependencias completas en el VPS"
        "d_njalla_sync      ➤ rsync local → VPS                 ➤ Sincroniza archivos locales al VPS"
        "d_resetdb          ➤ heroku pg:reset                   ➤ Reinicia completamente la base en Heroku"
        "d_run_local        ➤ -a -H -G -U -P -v                 ➤ Corre solo en local con todo"
        "d_run_local_heroku ➤ -a -G -P -v                       ➤ Corre en local + Heroku"
        "d_run_local_vps    ➤ -a -H -P                         ➤ Corre en local + VPS"
        "d_run_all          ➤ -a                               ➤ Corre en local + VPS + Heroku"
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
    opts=$(compgen -A alias | grep '^d_')
    COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
}

autoload -Uz compinit && compinit
compdef _d_aliases_autocomplete d_*

