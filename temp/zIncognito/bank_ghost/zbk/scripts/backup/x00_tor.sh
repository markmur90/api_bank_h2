#!/bin/bash

# 1. Lista todos los servicios relacionados con Tor para ver la instancia activa (habitualmente "default"):
systemctl list-units --type=service | grep tor

# 2. Arranca (y opcionalmente habilita al inicio) la instancia "default":
sudo systemctl enable --now tor@default

# 3. Verifica que ahora sí esté corriendo:
systemctl status tor@default --no-pager

# 4. Comprueba que el ControlPort esté abierto:
ss -tunlp | grep :9051
