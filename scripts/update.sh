if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get dist-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # MacOS
    brew update
    brew upgrade
fi
