#!/usr/bin/env bash
# Runbook for setting up a brand-new machine, written as a script so the steps stay accurate.
# Every step is idempotent: re-running the script skips anything that is already done.
# Run it directly (not via run_script), since it is meant to work before zsh and the shell functions are set up:
#   ~/dotfiles/scripts/new-machine-setup.sh
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

step() { echo -e "${YELLOW}==> $1${NC}"; }
done_msg() { echo -e "${GREEN}    $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Symlink $1 (a path in $HOME) to $2 (a path in this repo). Anything already at $1 that isn't that exact link (a file, folder, or symlink pointing elsewhere) is moved aside to $1.bak, or to a timestamped $1.bak.<time> if a .bak already exists, so no earlier backup is ever overwritten.
link_to_repo() {
  local target="$1" source="$2" name
  name="$(basename "$target")"
  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    done_msg "$name already linked."
    return
  fi
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    local bak="$target.bak"
    if [[ -e "$bak" || -L "$bak" ]]; then
      bak="$target.bak.$(date +%Y%m%d%H%M%S)"
    fi
    mv -- "$target" "$bak"
    done_msg "Moved existing $name to $(basename "$bak")."
  fi
  ln -s "$source" "$target"
  done_msg "Linked $name."
}

#######################################  Shared  ########################################

# Oh-My-Zsh, Powerlevel10k, and the zsh plugins. ~/.zshrc is linked to the repo first: on a new machine there is no ~/.zshrc yet, and the Oh-My-Zsh installer would otherwise write its own template there, which then blocks ./install from linking zsh/zshrc. omz-install.sh skips anything already installed.
install_oh_my_zsh() {
  step "Oh-My-Zsh, Powerlevel10k, and zsh plugins"
  link_to_repo "$HOME/.zshrc" "$DOTFILE_DIR/zsh/zshrc"
  "$SCRIPT_DIR/omz-install.sh"
}

########################################  macOS  ########################################

# Homebrew (also installs the Xcode Command Line Tools if they are missing). The installer asks for your password, so run this script in a real terminal. Apple Silicon only (/opt/homebrew); Intel Macs install to /usr/local and are not handled here.
mac_install_homebrew() {
  step "Homebrew"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    done_msg "Already installed."
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    done_msg "Installed."
  fi
  # Make brew available for the rest of this script. New shells get it from zsh/zshrc.
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

# MesloLGS NF, the font Powerlevel10k is designed for. Each file downloads to a .part file first and is only renamed into place once complete, so an interrupted download is retried on the next run instead of being mistaken for an installed font. After installing, set it as the font in iTerm2 (Settings > Profiles > Text > Font).
mac_install_p10k_font() {
  step "MesloLGS NF font (for Powerlevel10k)"
  local font_dir="$HOME/Library/Fonts"
  local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
  local styles=("Regular" "Bold" "Italic" "Bold Italic")
  local style file
  mkdir -p "$font_dir"
  for style in "${styles[@]}"; do
    file="MesloLGS NF ${style}.ttf"
    if [[ -f "$font_dir/$file" ]]; then
      done_msg "$file already installed."
    else
      curl -fsSL -o "$font_dir/$file.part" "$base_url/${file// /%20}"
      mv -- "$font_dir/$file.part" "$font_dir/$file"
      done_msg "Installed $file."
    fi
  done
}

# Link VS Code's user config to the repo. VS Code writes its own settings.json and snippets/ on first launch, which blocks ./install from linking them, so link_to_repo moves those aside first.
mac_link_vscode() {
  step "VS Code settings, keybindings, and snippets"
  local user_dir="$HOME/Library/Application Support/Code/User"
  local name
  for name in settings.json keybindings.json snippets; do
    link_to_repo "$user_dir/$name" "$DOTFILE_DIR/vscode/$name"
  done
}

# Install every extension listed in vscode/extensions.txt (blank lines and # comments are skipped). Already-installed extensions are skipped by VS Code itself. A failed install (e.g. an extension that was renamed or unpublished) is reported but doesn't stop the runbook.
mac_install_vscode_extensions() {
  step "VS Code extensions"
  local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
  if [[ ! -x "$code_bin" ]]; then
    done_msg "VS Code is not installed; skipping."
    return
  fi
  local id
  while IFS= read -r id || [[ -n "$id" ]]; do
    id="${id%%#*}"
    id="${id//[[:space:]]/}"
    [[ -z "$id" ]] && continue
    # </dev/null keeps the code CLI from reading the rest of the list off this loop's stdin.
    "$code_bin" --install-extension "$id" </dev/null || echo "    Failed to install $id."
  done <"$DOTFILE_DIR/vscode/extensions.txt"
}

setup_mac() {
  mac_install_homebrew
  mac_install_p10k_font
  install_oh_my_zsh
  mac_link_vscode
  mac_install_vscode_extensions
  # The remaining dotfiles are still linked by ./install (Dotbot); add their steps here as the chezmoi migration moves them.
}

########################################  Linux  ########################################

setup_linux() {
  echo "Linux setup is not written yet; nothing to do."
}

#######################################  Windows  #######################################

setup_windows() {
  echo "Windows setup is not written yet; nothing to do."
}

#########################################  Main  ########################################

case "$OSTYPE" in
  darwin*) setup_mac ;;
  linux-gnu*) setup_linux ;;
  msys* | cygwin* | win32*) setup_windows ;;
  *) echo "Unrecognized OS ($OSTYPE); nothing to do." ;;
esac

echo -e "${GREEN}New machine setup finished.${NC}"
