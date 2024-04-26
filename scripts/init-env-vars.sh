export HOME=/home/steven

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

export MANPATH="/usr/local/man:$MANPATH"

# Preferred editor
export EDITOR='nano'

export DOTFILE_DIR="$HOME/dotfiles"
export SOURCE_ALL_FUNCTIONS="$DOTFILE_DIR/functions/source-all-functions.sh"
# To detect if we are sourcing vs running the function
export SCRIPT_SOURCED="yes"
source $SOURCE_ALL_FUNCTIONS
unset SCRIPT_SOURCED

# Color codes
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m' # No Color
