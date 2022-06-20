#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo 'Starting update script!'
echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get dist-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    brew update --auto-update
    brew upgrade
fi

echo 'Update script finished!'
