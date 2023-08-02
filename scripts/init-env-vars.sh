export HOME=/home/steven

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

export MANPATH="/usr/local/man:$MANPATH"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nano'
else
  export EDITOR='nano'
fi

export DOTFILE_DIR="$HOME/dotfiles"
export SOURCE_ALL_FUNCTIONS="$DOTFILE_DIR/functions/source-all-functions.sh"
# To detect if we are sourcing vs running the function
export SCRIPT_SOURCED="yes"
source $SOURCE_ALL_FUNCTIONS
unset SCRIPT_SOURCED
