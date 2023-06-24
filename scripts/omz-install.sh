#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Ensure zsh exists and is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Installing ZSH..."
    # TODO: fix for Fedora
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt install -y zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    fi
    echo "ZSH has been installed."

    chsh -s $(which zsh)
    echo "Default shell has been changed to ZSH."
fi

# Install Oh-My-Zsh
if [[ ! -d $HOME/.oh-my-zsh ]]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --keep-zshrc --unattended
    echo "Oh-My-Zsh has been installed."
fi

# Install theme
if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k ]]; then
    echo "Installing theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    echo "Powerlevel10k has been installed."
fi

# Install plugins
if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]]; then
    git clone -q https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo "Installed ZSH autosuggestions."
fi

if [[ ! -d $ZSH_CUSTOM/plugins/zsh-syntax-highlighting ]]; then
    git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    echo "Installed ZSH syntax highlighting."
fi

if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/git-auto-status ]]; then
    git clone -q https://gist.github.com/475ee7768efc03727f21.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/git-auto-status
    echo "Installed git-auto-status."
fi

if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/auto-ls-zsh ]]; then
    git clone https://github.com/desyncr/auto-ls.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/auto-ls-zsh
    echo "Installed auto-ls."
fi

if [[ ! -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate ]]; then
    git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/autoupdate
    echo "Installed plugin autoupdate."
fi

echo "Your terminal is ready to go!"
