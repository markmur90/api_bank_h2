#!/usr/bin/env bash

# === ALIAS DE DESPLIEGUE PROFESIONAL ===

alias d_help='bash ./01_full.sh --help'
alias d_all='bash ./01_full.sh -a'
alias d_step='bash ./01_full.sh -s'
alias d_debug='bash ./01_full.sh -d'

# Despliegues comunes
alias d_local='bash ./01_full.sh -a -H -v -B -G -w'
alias d_heroku='bash ./01_full.sh -a -v -B -G -w'
alias d_production='bash ./01_full.sh -a -H -B -G -w'

# Reinstalación completa
alias d_reset_full='bash ./01_full.sh -a'

# Solo sincronizar archivos
alias d_sync='bash ./01_full.sh -B -H -G -C -M -P -D -Y -Z -U -l -w'

# Solo deploy a Heroku
alias d_push_heroku='bash ./01_full.sh -a -B -v -G -Z -M -P -D -Y -U -l -w'

# Solo VPS Njalla
alias d_njalla='bash ./01_full.sh -a -B -H -G -Z -Y -U -l -w'

# Menu interactivo
alias deploy_menu='bash ./scripts/multi_master.sh'


alias d_person='bash ./01_full.sh -a -L -U -V -v -u -p'