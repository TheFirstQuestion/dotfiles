#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Ensure zsh exists and is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    echo "Installing ZSH..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt install -y zsh
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    fi
    echo "ZSH has been installed."

    chsh -s $(which zsh)
    echo "Default shell has been changed to ZSH."
fi


# Install Oh-My-Zsh and plugins
if [[ ! -d $HOME/.oh-my-zsh ]]; then
    sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    echo "Oh-My-Zsh has been installed."

    echo "Installing theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

    echo "Installing plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    git clone https://gist.github.com/475ee7768efc03727f21.git $ZSH_CUSTOM/plugins/git-auto-status
    git clone https://github.com/rocktimsaikia/auto-ls-zsh.git $ZSH_CUSTOM/plugins/auto-ls-zsh
fi

echo "Your terminal is ready to go!"
