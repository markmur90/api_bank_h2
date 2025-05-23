#!/usr/bin/env bash

# === ALIAS DE DESPLIEGUE PROFESIONAL ===

alias d_help='bash ./01_full.sh --help'
alias d_all='bash ./01_full.sh -a'
alias d_step='bash ./01_full.sh -s'
alias d_debug='bash ./01_full.sh -d'

# Despliegues comunes

alias d_local='bash ./01_full.sh -a -Y -P -D -M -x -C -Z -L -S -U -V -p -u -H -B -v'
alias d_heroku='bash ./01_full.sh -a -L -U -V -p -u -v'
alias d_njalla='bash ./01_full.sh -a -L -U -V -p -u -H -B'

alias d_test='bash ./01_full.sh --dry-run -Y -Z -P -C -M -x -Q -I -l -G'