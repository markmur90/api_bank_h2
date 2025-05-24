#!/bin/bash
# Subida de código desde PC local al VPS
VPS_USER=markmur88
VPS_IP=80.78.30.188
rsync -avz ./api_bank_h2/ $VPS_USER@$VPS_IP:/home/$VPS_USER/api_bank/
