#!/usr/bin/env bash

# === ALIAS DE DESPLIEGUE PROFESIONAL ===

alias d_help='bash ./01_full.sh --help'
alias d_all='bash ./01_full.sh -a'
alias d_step='bash ./01_full.sh -s'
alias d_debug='bash ./01_full.sh -d'

# Despliegues comunes

alias d_local='bash ./01_full.sh --env=local -a -Y -P -D -M -x -Z -C -L -S -U -V -p -u -H -B -v'
alias d_heroku='bash ./01_full.sh --env=heroku -a -L -U -V -p -u -v -C'
alias d_varher='bash ./01_full.sh --env=production -a -L -U -V -p -v -C'
alias d_njalla='bash ./01_full.sh --env=production -a -L -U -V -p -u -H -B -C'
alias d_rsync='bash ./01_full.sh --env=local -a -Y -P -D -M -x -C -Z -Q -I -L -l -U -V -p -u -H -B -v -G -w'



# === DESPLIEGUE LOCAL COMPLETO ===
alias d_local2='bash ./01_full.sh --env=local -a -Y -Z -C -Q -I -L -U -u -G'

# === SINCRONIZACIÓN Y DESPLIEGUE HEROKU ===
alias d_heroku2='bash ./01_full.sh --env=heroku -a -Y -Z -C -Q -I -L -U -u -H -G'

# === DESPLIEGUE VPS NJALLA (PRODUCCIÓN) ===
alias d_production='bash ./01_full.sh --env=production -a -Y -Z -C -Q -I -L -V -v -U -G'

# === VERSIÓN LIGERA PARA PRUEBAS LOCALES ===
alias d_local_dry='bash ./01_full.sh --env=local -a --dry-run -Y -Z -C -Q -I -L -U -u -G'

# === DESPLIEGUE CON ACTUALIZACIÓN DE VARIABLES DE HEROKU (extra seguro) ===
alias d_heroku_safe='bash ./01_full.sh --env=heroku -a -Y -Z -C -Q -I -L -u -H -B -G'

# === DEPLOY MINIMALISTA DE PRODUCCIÓN (sin regenerar datos) ===
alias d_prod_min='bash ./01_full.sh --env=production -a -v -G'

# === DESPLIEGUE COMPLETO CON TODO CONFIGURADO (ideal primer VPS) ===
alias d_prod_full='bash ./01_full.sh --env=production -a -Y -Z -C -Q -I -v -U -L -U -G -p -x'

