#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Ensure zsh exists and is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        apt install zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    fi
    echo "ZSH has been installed."

    chsh -s $(which zsh)
    echo "Default shell has been changed to ZSH."
fi


# Install Oh-My-Zsh
if [[ ! -d $HOME/.oh-my-zsh ]]; then
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    echo "Oh-My-Zsh has been installed."
fi
