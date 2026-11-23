# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo managed by [Dotbot](https://github.com/anishathalye/dotbot). Everything in here gets symlinked into the home directory via `install.conf.yaml`. Changes in this directory are immediately live because the target paths are symlinks.

## Key commands

**New machine runbook** (run before `./install`; branches on OS, only macOS is implemented — installs Homebrew, the GitHub CLI (`gh`), the MesloLGS NF font, and Oh-My-Zsh with Powerlevel10k and plugins, links `~/.zshrc` and VS Code's settings/keybindings/snippets, and installs the extensions in `vscode/extensions.txt`). Prerequisites on macOS: Visual Studio Code and iTerm2 installed in `/Applications`; the script stops if either is missing. Every step is idempotent, and new setup steps belong here:

```sh
./scripts/new-machine-setup.sh
```

**Install / re-install everything** (symlinks, submodules, Oh-My-Zsh):

```sh
./install
```

**Pull latest and reinstall** (the `dotbot` shell function, available after zsh is sourced):

```sh
dotbot
```

**Run a script from `scripts/`** (the `run_script` shell function):

```sh
run_script <script-name>   # e.g. run_script update, run_script init-archive
```

**Common scripts:**

- `run_script update` — upgrade OS packages (handles Fedora, Mint, macOS/brew)
- `run_script init-archive` — initialize personal folder structure

**Copy a template into the current directory:**

```sh
template README       # → README.md
template gitignore    # → .gitignore
template env          # → .env.local
```

## Architecture

### Dotbot (`install.conf.yaml`)

The single source of truth for what gets symlinked where. It:

1. Creates symlinks from home directory paths → files in this repo.
2. Runs `git submodule update --init --recursive` (Dotbot itself is a submodule in `dotbot/`).
3. Runs `scripts/omz-install.sh` to ensure Oh-My-Zsh is present.

### Shell initialization chain

`~/.zshrc` → `scripts/init-env-vars.sh` → `functions/source-all-functions.sh` → sources every file in `functions/` individually.

All custom shell functions live in `functions/`. Adding a new `.sh` file there makes it available in every new shell automatically — no manual sourcing needed.

### Key environment variables (set in `scripts/init-env-vars.sh`)

- `$DOTFILE_DIR` — absolute path to this repo (`~/dotfiles`)
- `$SOURCE_ALL_FUNCTIONS` — path to the function loader
- `$ZSH` / `$ZSH_CUSTOM` — Oh-My-Zsh paths
- Color codes: `$RED`, `$GREEN`, `$YELLOW`, `$NC`

### Directories and what they configure

| Directory | Target |
| ----------- | -------- |
| `zsh/` | `~/.zshrc`, `~/.p10k.zsh` |
| `git/` | `~/.gitconfig` |
| `ssh/` | `~/.ssh/config` |
| `vscode/` | VS Code settings, keybindings, snippets, `.editorconfig` |
| `prettier/` | `~/.prettierrc.js`, `~/.prettierrc.yaml` |
| `iterm/` | iTerm2 color scheme (`brogrammer.itermcolors`) |
| `musescore/` | Plugins, styles, templates |
| `archive/` | Configs, scripts, and assets for tools no longer in active use (Atom, i3, polybar, rofi, dunst, autorandr, Nemo, conda, Firefox, Terminator, feh, and old Linux scripts) |
| `claude/` | Claude Code global config (`settings.json`, `CLAUDE.md`) |
| `semgrep/` | Local-only custom lint rules for VSCode (via Semgrep extension) |
| `assets/` | `ding.wav`, the sound played by the Claude Code hooks in `claude/settings.json` |
| `docs/` | Notes (e.g. `local-overrides.md`) |
| `templates/` | Starter files (`README`, `gitignore`, `env`) |
| `functions/` | Custom zsh functions (auto-sourced at shell start) |
| `scripts/` | Runnable scripts (invoked via `run_script`) |

### Supporting multiple operating systems

Each file or script handles the operating systems it supports independently, rather than the repo being split into per-OS directories or per-OS install entries. A script branches on `$OSTYPE` internally (see `scripts/new-machine-setup.sh`, `scripts/update.sh`, and `functions/notify.sh`), and a config file only carries settings for the platforms it actually serves.
