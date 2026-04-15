# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A personal dotfiles repo managed by [Dotbot](https://github.com/anishathalye/dotbot). Everything in here gets symlinked into the home directory via `install.conf.yaml`. Changes in this directory are immediately live because the target paths are symlinks.

## Key commands

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
|-----------|--------|
| `zsh/` | `~/.zshrc`, `~/.p10k.zsh`, Terminator config |
| `git/` | `~/.gitconfig` |
| `ssh/` | `~/.ssh/config` |
| `vscode/` | VS Code / VSCodium settings, keybindings, snippets, `.editorconfig` |
| `prettier/` | `~/.prettierrc.js`, `~/.prettierrc.yaml` |
| `i3/` | i3 window manager config, xbindkeys |
| `polybar/` | Polybar config and launch script |
| `dunst/` | Notification daemon config |
| `rofi/` | App launcher config |
| `autorandr/` | Display profile configs |
| `conda/` | `~/.condarc` |
| `atom/` | Atom editor config, styles, snippets |
| `firefox/` | `userChrome.css` |
| `nemo/` | File manager config |
| `musescore/` | Plugins, styles, templates |
| `archive/` | Configs for tools no longer in active use (e.g. `atom/`) |
| `claude/` | Claude Code global config (`settings.json`, `CLAUDE.md`) |
| `templates/` | Starter files (`README`, `gitignore`, `env`) |
| `functions/` | Custom zsh functions (auto-sourced at shell start) |
| `scripts/` | Runnable scripts (invoked via `run_script`) |
| `cron/` | Cron job scripts (e.g. `automated_backup.sh`) |

### macOS vs Linux
`install.conf.yaml` has separate symlink entries for VSCode on Linux (`~/.config/VSCodium/`) and macOS (`~/Library/Application Support/Code/`). The `scripts/update.sh` script also branches on `$OSTYPE`.
