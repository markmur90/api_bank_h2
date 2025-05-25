#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update && sudo apt-get full-upgrade -y && sudo apt-get autoremove -y && sudo apt-get clean
echo -e "\033[7;30m🔄 Sistema actualizado.\033[0m"
echo -e "\033[7;94m---///---///---///---///---///---///---///---///---///---\033[0m"
echo ""