# Import custom functions
source $SOURCE_ALL_FUNCTIONS

echo 'Starting update script!'
echo ""

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Linux

  # This gives us info about what distro and version
  source /etc/os-release

  if [[ "$ID" == "fedora"* ]]; then
    # Fedora
    echo 'Upgrading packages...'
    sudo dnf upgrade -y
    echo 'Done!'
    echo

    echo 'Removing packages...'
    sudo dnf autoremove -y
    sudo dnf clean packages -y
    echo 'Done!'
    echo

    # Update Discord
    run_script update_discord
  elif [[ "$ID" == "linuxmint"* ]]; then
    # Mint
    sudo -- sh -c 'apt-get update; apt-get upgrade -y; apt-get dist-upgrade -y; apt-get autoremove -y; apt-get autoclean -y'
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # MacOS
  brew update --auto-update
  brew upgrade
fi

echo 'Update script finished!'
