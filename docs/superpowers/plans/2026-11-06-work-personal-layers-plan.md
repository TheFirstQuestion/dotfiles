# Work / personal config layers — plan

Condensed from `docs/superpowers/specs/2026-11-06-work-personal-layers-design.md`. Updated 2026-11-23 to match the repo after PR #1 (new-machine runbook, local-override includes) and PR #2 (cleanup and Linux archive) landed on `main`.

## Repo state this plan builds on (2026-11-23)

- `main` (at `ada7239`) and `v1-v2-migration` (tip `8ef3a8b`, the merge of `main` into it) have identical trees. The Dotbot setup is still live and `install.conf.yaml` holds 22 links, all macOS.
- All Linux/X11 config was moved to `archive/` (i3, polybar, rofi, dunst, autorandr, nemo, conda, firefox with its fox images, terminator, feh, the wallpapers, `cron/automated_backup.sh`, `connect_headphones`, `dropbox_sync`, `tzupdate`, `update_discord`, `next_available_ws.sh`, `tzupdate.py`). Nothing under `archive/` is applied.
- `scripts/new-machine-setup.sh` is the new-machine runbook (becomes the root `install.sh`; see "`install.sh`") (macOS only; Linux and Windows are stubs). It installs Homebrew, `gh`, `node`, the MesloLGS NF font, Oh-My-Zsh/p10k/plugins (via `omz-install.sh`), and VS Code extensions from `vscode/extensions.txt`; it symlinks `~/.zshrc` and the VS Code settings. Repo `CLAUDE.md` says new setup steps belong in it.
- Machine-only override files exist and are untracked: `~/.ssh/config.local` (included first by `ssh/config`), `~/.gitconfig.local` (included last by `git/gitconfig`), `~/.zshrc.local` (sourced near the end of `zsh/zshrc`), `~/.claude/settings.local.json`. They are documented in `docs/local-overrides.md`. Personal ssh hosts (`myth`, `nas`, `sLaptop`) were removed from `ssh/config`.
- Repo `CLAUDE.md` states a principle: each file handles the operating systems it supports itself (`$OSTYPE` branches) instead of per-OS directories. See "Open decisions".
- `iterm/brogrammer.itermcolors` is now a top-level folder (was `theme-files/`). `assets/` holds only `ding.wav`.
- The `Bedrock` `env` block was removed from tracked `claude/settings.json`.
- Tag `v1_last` and branch `v1` still point at `0e1028c`, which predates all of the above.
- Live Claude state on `wMac01` (read 2026-11-23, not in the repo): `~/.claude` is a symlink to `/Volumes/External/Caches/claude`; the live `~/.claude/settings.json` has `autoMode` (24 `environment` strings) and `env` (`AWS_REGION`, `CLAUDE_CODE_USE_BEDROCK`), neither in the repo copy; and 10 hook entries run `/Users/steven/.config/iterm2/cc-status`, also absent from the repo copy. `~/.config/iterm2/cc-status` is a symlink into the iTerm2 app bundle (`/Applications/iTerm.app/Contents/Resources/utilities/cc-status`), so the repo has no iTerm hook script to ship, only hook registrations to recover from the live file.
- `chezmoi` is not installed on `wMac01` yet, so no chezmoi behavior in this plan has been run. See the verification task under "Builder tasks".

## Machines and groups

- `wMac01`: work Mac (group `work/Dimer_Health`).
- `sMac02`: personal Mac (group `personal`).

## Constraints

- Give every file one applicability: everywhere, one OS, one group, or one machine.
- Choose machine config from chezmoi data stored once per machine: `group`, `machine`. Detect OS.
- Handle OS differences with chezmoi data and runtime checks in shell code.
- Allow work and personal to differ in any file.
- Support `chezmoi apply -n` and `chezmoi diff` before any write. Detect live files edited outside the repo before overwriting.
- Document layout, layering rules and the edit-then-apply workflow in README + CLAUDE.md.
- Do not build a multi-employer framework. Do not build secret storage: secrets stay in untracked, hand-edited local files (user decision 2026-11-23; no Bitwarden).
- Change config contents only to remove hardcoded paths, split out machine-specific parts, or turn files into templates.
- Keep `~/.ssh/config.local`, `~/.gitconfig.local` and `~/.zshrc.local` as hand-edited, unmanaged files. chezmoi never writes them. Keep the `Include` at the top of the ssh template, the `[include]` at the end of the git template, and the `source` of `~/.zshrc.local` near the end of the zshrc template so their values still win (see "Secrets").
- Support macOS only. Do not render, test or document Linux apply paths.

## Acceptance checks (failure if any is false)

- No secret is committed or rendered into a tracked file.
- Applying on one machine does not break or overwrite another machine's setup.
- Live config does not silently drift from the repo.
- A new Mac is set up by: clone the repo, run `install.sh` (installs chezmoi with the other tools, then applies; macOS only for now). Then create the untracked local files that machine needs (`~/.zshrc.local` and, on a work machine, the untracked Claude fragment; see "Secrets").
- Cutover loses no live content on either Mac.

## Archive of the old design

- Branch `v1` and tag `v1_last` point at commit `0e1028c` (pushed, public, unrewritten). Use them only to copy from the older layout. No rollback is planned.

## Tooling

- Remove Dotbot and its submodule. Use chezmoi.
- No secret store: no `bw`, no Bitwarden template functions.
- Document: Claude cannot answer drift prompts, so it applies with `dotapply --headless`.
- Document: chezmoi writes real files, not symlinks. Edit the repo, then run `chezmoi apply`.

## Repo layout

```
dotfiles/
├── .chezmoiroot            contains "home"
├── install.sh              entry point (was scripts/new-machine-setup.sh): installs tools incl. chezmoi, then `chezmoi init --apply`; run from the checkout; outside `home/`, so never applied
├── README.md  CLAUDE.md  docs/
├── assets/                 binary resources; never applied
│   └── audio/              ding.wav
├── archive/                dead tools, including the retired Linux desktop config; never applied
├── templates/              starter files (README, gitignore, env, claudeignore); never applied; read via DOTFILE_REPO_PATH
├── semgrep/                custom lint rules; never applied; VS Code reads ~/dotfiles/semgrep/rules from the checkout
├── layers/                 merged fragments
│   ├── shared/             claude/settings.json  vscode/settings.json  zsh/env.zsh ...
│   ├── macos/              (no linux/ until Linux returns)
│   ├── work/Dimer_Health/  (wMac01/ inside)
│   └── personal/           (sMac02/ inside)
└── home/                   chezmoi source tree, named after target paths
    ├── .chezmoi.toml.tmpl      prompts once for group and machine; records os/group/machine; sets sourceDir
    ├── .chezmoiignore          templated filter
    ├── .chezmoiexternal.toml   oh-my-zsh, plugins, p10k
    ├── .chezmoitemplates/      shared templates, including the JSON merge
    ├── .chezmoiscripts/        run scripts (migration, Archive-folder check)
    └── dot_*, private_*, ...
```

- Whole files live in `home/` under their target names; `layers/` holds only merged fragments (`claude/settings.json`, `vscode/settings.json`, `claude/CLAUDE.md`, `git/gitconfig`, `zsh/env.zsh`). The headings under "Classification" say where something applies, not which directory holds it.
- Put root-level chezmoi files (`.chezmoi.toml.tmpl` etc.) inside `home/`.
- Set `sourceDir = ~/dotfiles` in `chezmoi.toml` from `.chezmoi.toml.tmpl` (`.chezmoiroot` then makes `~/dotfiles/home` the root); `--source` is not remembered after `chezmoi init`.
- Keep the chezmoi source directory at `~/dotfiles` on every machine.

## Layering rules

- Read layers in this order, later overrides earlier: `shared` → OS layer (`macos` only for now; add `linux` when Linux returns) → group layer (`work/Dimer_Health` or `personal`) → machine layer (`work/Dimer_Health/wMac01`, `personal/sMac02`).
- Store `group` and `machine` in `~/.config/chezmoi/chezmoi.toml` (from `.chezmoi.toml.tmpl` prompts). Build the machine layer path as `layers/<group>/<machine>`.
- Take OS from `.chezmoi.os`. Map `darwin` → `macos` layer directory in the merge template.
- Give group and machine layers no OS subfolders.
- Express layers two ways:
  - Whole files that apply to some machines: put in `home/` under the target name; filter with `.chezmoiignore` (OS ignore, group ignore, or machine ignore).
  - Files whose content differs by layer (Claude `settings.json`, VS Code `settings.json`, git config, zsh env): make templates in `home/` that read fragments from `layers/<layer>/...` in the order above.
  - zsh `env.zsh` fragments are inlined into the zshrc template in layer order (skip missing), before the line that sources `~/.zshrc.local`, so `~/.zshrc.local` still wins.
- Reach layer files with absolute paths: `{{ .chezmoi.workingTree }}/layers/shared/claude/settings.json` via `include` / `stat`. `stat` returns false for a missing path.
- Answer prompts non-interactively with `chezmoi init --promptString group=<value>`.

## `.chezmoiignore`

- One file, always a template. Match target paths relative to `~`.
- Order sections like the layers: OS, group, machine. One comment header per section.
- One `{{ if ... }}` block per section listing target paths to ignore; each path appears once.
- Write conditions as "not this X" (e.g. `{{ if ne .chezmoi.os "darwin" }}`). Group paths by tool within a section.
- Example: ignore the iTerm2 files unless OS is darwin; ignore the `parse-logs` skill unless group is work.
- No entry needed for `install.sh`: it sits at the repo root, outside `home/` (the chezmoi root), so chezmoi never sees it.

## Run scripts and externals

- Put run scripts in `home/.chezmoiscripts/` (`before_` / `after_`).
- `run_once_` / `run_onchange_` key on rendered content SHA256. Editing a script re-runs it.
- Scripts do not run under `apply -n`. Scripts run with the real `HOME`.
- Do not pin (user decision): oh-my-zsh, plugins and p10k should keep updating. Declare them in `.chezmoiexternal.toml` as `type = "git-repo"` tracking the default branch, with `refreshPeriod` (for example `"168h"`) and shallow clones (`clone.args = ["--depth", "1"]`, `pull.args = ["--ff-only"]`). No tag, commit or checksum. `chezmoi apply --refresh-externals` forces an update now. Trade-off the user accepted: whatever the upstream default branch holds runs as shell code in every new shell. Builder task: confirm `git-repo` works for the `git-auto-status` gist (otherwise use a `file` external with the raw URL).
- Replace the `omz-install.sh` step with the externals. Remove `scripts/omz-install.sh` and drop its call (and the zshrc symlink workaround) from `install.sh`. Keep its "ensure zsh is the default shell" logic only if still needed (macOS ships zsh).
- `omz-install.sh` clones oh-my-zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, git-auto-status (a gist), auto-ls, autoupdate, zsh-safe-rm, zsh-better-npm-completion, conda-zsh-completion and zsh-extract. Declare only what `zsh/zshrc` uses: oh-my-zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, git-auto-status, zsh-better-npm-completion. Do not declare `autoupdate` and `zsh-safe-rm` (commented out in `plugins=`), `auto-ls` (the zshrc sources the repo's own `zsh/auto-ls.zsh`, not the plugin), or `zsh-extract` (`plugins=` lists oh-my-zsh's built-in `extract`). Conda is retired (user decision 2026-11-23): do not declare `conda-zsh-completion`, and delete its `plugins=` entry.

## Assets

- Keep `assets/` top-level, sorted by file type (`audio/`; new type → new folder). Never apply it.
- `assets/audio/`: `ding.wav` (move it from `assets/ding.wav`). It is the only live asset; the images and Linux helper scripts are in `archive/`.
- Replace the `/Users/steven/dotfiles/assets/ding.wav` literals in Claude hooks with a path filled from `.chezmoi.workingTree` (see "Sound hooks").

## `DOTFILE_REPO_PATH` and applied code

- Applied code: chezmoi copies `functions/` and `scripts/` to `~/.local/share/dotfiles/functions/` and `~/.local/share/dotfiles/scripts/` (no subfolders, names unchanged), and `zsh/auto-ls.zsh` to `~/.local/share/dotfiles/zsh/auto-ls.zsh`. The shell runs or sources these copies.
- Repo-only content (`assets/`, `templates/`, `semgrep/`, `archive/`) is read from the checkout.
- `DOTFILE_REPO_PATH` = the repo checkout (`~/dotfiles`). Use it only for repo-only content (`template`, `backup.sh` read `$DOTFILE_REPO_PATH/templates/`).
- Never use it to find `functions/` or `scripts/`. `source-all-functions.sh`, `run_script` and `list-commands.sh` read the applied directories.
- Set and export `DOTFILE_REPO_PATH` only in the zshrc template (filled from `.chezmoi.workingTree`, before anything is sourced). Remove the `export DOTFILE_REPO_PATH=...` line from `init-env-vars.sh`. The zshrc template sources `init-env-vars.sh` from the applied scripts directory.
- Document in README and CLAUDE.md: meaning of `DOTFILE_REPO_PATH`, applied-vs-repo split, the zshrc template sets it, `init-env-vars.sh` cannot run alone without it, dependent scripts expect a shell that loaded `~/.zshrc`.
- Replace the hardcoded `$HOME/dotfiles/...` lines in `zshrc`: `source $HOME/dotfiles/scripts/init-env-vars.sh` becomes the applied `~/.local/share/dotfiles/scripts/init-env-vars.sh`, and `source $HOME/dotfiles/zsh/auto-ls.zsh` becomes the applied `~/.local/share/dotfiles/zsh/auto-ls.zsh`. `functions/notify.sh` still holds `$HOME/dotfiles/assets/ding.wav` in its Linux branch; the change under "Sound hooks" removes it. `tzupdate.sh` is archived.
- Rename `DOTFILE_DIR` → `DOTFILE_REPO_PATH` everywhere. Files: repo `CLAUDE.md`, `functions/source-all-functions.sh`, `functions/template.sh`, `functions/run-script.sh`, `scripts/backup.sh`, `scripts/init-env-vars.sh`, `scripts/list-commands.sh`, `install.sh` (it derives its own value from the script location; rename the local variable for consistency) (`functions/dotbot.sh` is deleted). Verify with a repo-wide search for `DOTFILE_DIR` excluding `archive/` and git history.
- Check `~/.zshrc.local` and Claude skills/global instructions outside the repo for `DOTFILE_DIR`; report to the user, do not edit.
- Keep the name `SOURCE_ALL_FUNCTIONS`; point it at the applied loader.

## OS handling

- Use `.chezmoi.os` and `.chezmoiignore` for whole-file applicability.
- Check at runtime in shell/script code (e.g. detect the Homebrew prefix, not `/opt/homebrew`). No `/home/steven` or `/Users/steven` literals. Remaining literals to fix: `zsh/zshrc` (`/opt/homebrew/opt/ruby/bin` → `$HOMEBREW_PREFIX/opt/ruby/bin`; the `/home/steven/...`, maven and `GOPATH` lines are Linux-only and are deleted, since the Linux laptop is retired and archived; git history keeps them), `vscode/settings.json` (`python.defaultInterpreterPath` (Linux-only: delete it), `dart.flutterSdkPath`), `claude/settings.json` (`/Users/steven/.claude/...` permission paths and the `ding.wav` hooks), `claude/CLAUDE.md` (lines 80 and 83 use `/Users/steven/Archive/04_Projects/dimer-flutter` as a `git -C` example: replace with a neutral `<repo-path>`), and `functions/notify.sh` (`$HOME/dotfiles/assets/ding.wav`). `vscode/settings.json` `semgrep.scan.configuration` (`~/dotfiles/semgrep/rules`) stays as is: the checkout is always at `~/dotfiles`, and `~` is not user-specific.
- `zsh/zshrc` already guards Homebrew with `[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon only). Keep that guard or replace it with a runtime lookup; do not regress it.
- Home-directory paths inside JSON fragments (the `/Users/steven/.claude/...` permission rules, `dart.flutterSdkPath`): fragments are read raw, so template data is not available in them. Write them `~/`-relative. Builder task: confirm that Claude permission rules (`Read(...)`, and `Bash(...)`, which match the command text) and Dart-Code accept `~`; for any that do not, put the token `__HOME__` in the fragment and have the merge template replace it with `.chezmoi.homeDir` before parsing.
- Conda is retired (user decision 2026-11-23): delete the `conda init` block (it hardcodes `/opt/homebrew/Caskroom/miniconda/base`), the `conda-zsh-completion` plugin entry, and `conda` from `AUTO_LS_COMMANDS` in `zsh/auto-ls.zsh`. Git history keeps them.

## Git and GitHub identity

- Duplicate git/ssh/gh identity setup in the work and personal layers. Keep them separate.
- Fix `core.excludesfile = ~/dotfiles/gitignore` in `gitconfig`: the root `gitignore` file no longer exists. Point the git config template at a path that does (real file: `templates/gitignore`, via `DOTFILE_REPO_PATH`).
- Keep the trailing `[include] path = ~/.gitconfig.local` in the git template, and the leading `Include ~/.ssh/config.local` in the ssh template. Both local files stay unmanaged.
- Create both templates (not yet created): turn `git/gitconfig` into `home/dot_gitconfig.tmpl` and `ssh/config` into `home/private_dot_ssh/private_config.tmpl`. The git template holds the shared settings and pulls the `[user]` identity from layer fragments (`layers/<group>/git/gitconfig`, then `layers/<group>/<machine>/git/gitconfig`; later wins; skip missing). The ssh template is applied on personal machines only (gate it in `.chezmoiignore`).

## JSON merge (generated files)

- Generate Claude `settings.json` and VS Code `settings.json` by merging layer fragments.
- Fragments: strict JSON, one file per layer under `layers/<layer>/<tool>/`. Skip missing files. For Claude `settings.json` only, the untracked machine-local fragment `~/.config/dotfiles/claude.local.json` (outside the repo; see "Claude settings scope") is read last, after the machine layer's `settings.json`; reach it with `{{ .chezmoi.homeDir }}/.config/dotfiles/claude.local.json` via `stat` / `include`. chezmoi does not manage that file.
- Semantics: objects deep-merge, arrays concatenate and de-duplicate, scalars take the most specific layer. No remove syntax; put non-universal entries in a group/machine layer. Claude `deny` still beats `allow`.
- Implement in one template in `home/.chezmoitemplates/` using chezmoi's `jq` function (`jq query input`, gojq, returns a list → take `first`). Apply the program to the list of layer documents, least to most specific.
- Use this program exactly:

```
def dedup: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
def merge($a; $b):
  if ($a|type) == "object" and ($b|type) == "object" then
    reduce (($a|keys) + ($b|keys) | unique)[] as $k ({};
      .[$k] = (if ($a|has($k)) and ($b|has($k)) then merge($a[$k]; $b[$k])
               elif ($b|has($k)) then $b[$k] else $a[$k] end))
  elif ($a|type) == "array" and ($b|type) == "array" then ($a + $b | dedup)
  else $b end;
reduce .[1:][] as $l (.[0]; merge(.; $l))
```

- Test against gojq with `chezmoi execute-template`.
- Move the one `//` comment in old `vscode/settings.json` (line 59) into the template as a template comment.

## Claude settings scope

- Put everything that must apply in every project (permissions, `additionalDirectories`, `enabledPlugins`) in `~/.claude/settings.json`. `~/.claude/settings.local.json` isn't a documented settings file (the docs list only user `~/.claude/settings.json`, project `.claude/settings.json`, project-local `.claude/settings.local.json`, and managed settings), so don't rely on it. The builder tests whether an `additionalDirectories` entry there takes effect from a session started outside `~`, and designs `add-allowed-directory.sh` around the result, since the change to that script rests on it.
- Change `add-allowed-directory.sh` to:
  - append the directory to `permissions.additionalDirectories` in the untracked fragment `~/.config/dotfiles/claude.local.json` (create the directory and file if missing; idempotent; strict JSON). It lives outside the repo because these paths reveal private project layout (see "Sanitization") and worktree paths are ephemeral, so it can never be committed and needs no `.gitignore` entry;
  - then run `dotapply --headless`; if it exits non-zero, print the error and exit non-zero.
- The same untracked fragment holds the full `autoMode.environment` array (the detailed text that must stay out of git). No tracked fragment carries `autoMode.environment`, because arrays concatenate in the merge and a tracked generic array would be added to the full one rather than replaced. A machine without the fragment gets no `autoMode.environment`. The fragment is created by hand (Migration step 2 seeds it from the live `~/.claude/settings.json`), exists only on disk (chezmoi neither writes nor removes it), and is backed up by the user.
- Update the `add-allowed-directory.sh` row in `claude/CLAUDE.md` (line 57): new target file and the `dotapply --headless` step.
- Update `claude/skills/find/SKILL.md` (lines 71-72, 88) and `claude/skills/set-up-worktree/SKILL.md` (lines 126-127) only if their wording relies on the old `settings.local.json` behavior.

## Drift handling

- Let chezmoi prompt: if the live file differs from what chezmoi last wrote, show a diff and ask before overwriting. Fold worthwhile live edits into the right `layers/` fragment.
- Use `--error-on-conflict` for non-interactive runs; check the exit code (it prints nothing). Unverified: `chezmoi` is not installed yet, so the builder confirms this flag exists (see "Builder tasks"). If it does not, headless mode needs another way to refuse to overwrite drifted files, and the user is told before proceeding.
- Never use `--force` for routine applies.
- Document: edit with `chezmoi edit` or directly in `home/` and `layers/`, then apply. `chezmoi re-add` works only for non-template files.

## Sound hooks

- Add `functions/play-sound.sh` (a template; bakes in the `assets/audio/ding.wav` path) defining `play_sound`.
- `play_sound` takes an optional sound path (default `ding.wav`) and picks the player at runtime: `afplay`, then `paplay`, `pw-play`, `aplay`; no player → silent no-op.
- Replace the Claude hooks that play `ding.wav`: three hooks (`PreToolUse` on `AskUserQuestion`, `Stop`, `PermissionRequest`) holding four commands (three `afplay /Users/steven/dotfiles/assets/ding.wav` and one `paplay /home/steven/dotfiles/assets/ding.wav`, the latter in the `AskUserQuestion` hook). Each hook gets one `zsh -c 'source ~/.local/share/dotfiles/functions/play-sound.sh && play_sound'` command (keep `"async": true`); the `paplay` command disappears. Define them once in `layers/shared/claude/settings.json`. Keep sound hooks out of the `macos/` fragment.
- Make `functions/notify.sh` call `play_sound` in place of its `paplay` and `afplay` lines. 

## Secrets

- Secrets live only in untracked files you edit by hand (user decision 2026-11-23: these files exist precisely to keep secrets out of git, so nothing generates them). They are `~/.zshrc.local` (mode 600), `~/.ssh/config.local`, `~/.gitconfig.local`, and the untracked Claude fragment `~/.config/dotfiles/claude.local.json` (see "Claude settings scope").
- `~/.zshrc.local` stays exactly as today: hand-edited, untracked, never written by chezmoi, sourced near the end of the zshrc template after the `env.zsh` fragments so it still wins. It holds `ATLASSIAN_API_EMAIL`, `ATLASSIAN_API_TOKEN`, `TICKET_BASE_URL` and the Bedrock model ARNs (`ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL`), because the ARNs embed the employer's AWS account ID and the ticket URL is an internal domain. No cutover step touches it. Leave `docs/local-overrides.md` and the `zshrc` comment ("not tracked in git") as they are, apart from the row in the next bullet.
- Add a row to `docs/local-overrides.md` for the generated Claude `settings.json` and its layers.
- Put non-secret environment (AWS profile name, region, PATH entries) in tracked `layers/.../zsh/env.zsh` going forward. Do not move anything out of the existing `~/.zshrc.local` for the migration.
- List in the README the variable names each group expects in `~/.zshrc.local` (names only, never values) so a new machine can be set up by hand. Because the file is never generated, a missing variable only breaks the tool that reads it.
- Keep `.claude/settings.local.json` untracked.
- Failure policy: nothing depends on a secret store, so there is no secret-related abort. A missing untracked fragment or `~/.zshrc.local` is skipped. Templates never reference secrets.
- Verification renders (dry-runs, scratch applies) need no placeholders. The templates read the untracked fragment from the real `~/.config/dotfiles/claude.local.json` (`.chezmoi.homeDir`, not the scratch destination), read-only, so a scratch render includes the real `autoMode`.
- Add a `run_before_` check: abort the apply with "run `run_script init-archive ~/Archive`" if the top-level folders `init-archive` creates are missing. `install.sh` runs `init-archive` before the first apply. Without it, chezmoi may write earlier files before a later template errors (the builder confirms this ordering).
- Fix `scripts/init-archive.sh` to create `04_Projects` (underscore), not `04 Projects`.
- Do not check `~/.claude` → `/Volumes/External/Caches/claude` on apply (`wMac01` only).

## Bedrock and AWS environment

- Keep `CLAUDE_CODE_USE_BEDROCK` and `AWS_REGION` in the `env` block of the tracked Claude work fragment `layers/work/Dimer_Health/claude/settings.json` (where the live `settings.json` has them today, so sessions that don't start from a shell still get them), and `AWS_PROFILE` in tracked `layers/work/Dimer_Health/zsh/env.zsh` (it is not in the live `settings.json` `env`; confirm where it is set today by reading `~/.zshrc.local`). If the profile name embeds the account ID or internal naming, leave it in `~/.zshrc.local`.

## `install.sh` (repo root; replaces the Dotbot `./install` and `scripts/new-machine-setup.sh`)

- Create `install.sh` at the repo root by `git mv scripts/new-machine-setup.sh install.sh` (one entry point, no second script). It takes over the Dotbot `./install` name: delete the old `install` file in the same change. Update repo `CLAUDE.md` (the "New machine runbook" section, key commands, and the line saying new setup steps belong in it) and `README.md` to name `./install.sh`. Fix anything in the script that finds the repo from its `scripts/` location (it now lives at the root). Keep its OS branch (`setup_mac`; Linux and Windows stubs stay), idempotent steps, prerequisite check (VS Code, iTerm2 in `/Applications`), Homebrew install, `gh`/`node` packages, MesloLGS NF font, and VS Code extension install.
- Add `chezmoi` to the Homebrew package list (it skips installed tools). The runbook installs Homebrew itself, so drop the old "stop if `brew` is missing" rule.
- Remove the steps chezmoi replaces: `install_oh_my_zsh` (externals), `mac_link_vscode` and the `link_to_repo` helper (VS Code files and `~/.zshrc` come from chezmoi). Remove the stale "remaining dotfiles are linked by ./install (Dotbot)" comment.
- The repo is cloned to `~/dotfiles` before running it (the script lives in the repo); keep that as the first README step.
- After the tool steps, run `init-archive`, then `chezmoi init --apply --source ~/dotfiles`.

## `dotapply` (replaces `dotbot`; delete `functions/dotbot.sh`)

- Create `functions/dotapply.sh`.
- Default mode, in order:
  1. `git -C "$DOTFILE_REPO_PATH" pull`
  2. `chezmoi apply` (plain, so drift prompts).
  3. `omz reload`
- `--headless` mode (for Claude; it cannot answer drift prompts):
  - skip `git pull` and `omz reload`;
  - run `chezmoi apply --error-on-conflict`.
- Headless writes real files to the real home. No template depends on a mode flag or a secret store.
- Never pass `--force`.
- On a new machine the first apply comes from `install.sh`, not `dotapply`.

## Migration

1. (Done 2026-11-23.) Build in the separate worktree `~/dotfiles-chezmoi` on `v1-v2-migration`. `~/dotfiles` is on `main`. Do not restructure the checkout live links point at. Merge `main` into the branch before each work session so the branch never drifts from the live repo.
2. Reconcile drift first: back up the live `~/.claude/settings.json`; diff it against the repo copy (the known differences are the live `autoMode`, `env` and iTerm `cc-status` hooks; see "Repo state"). Move the `autoMode` block into the untracked `~/.config/dotfiles/claude.local.json` (not into any tracked fragment), `env` to the work fragment, and the iTerm hook registrations to `layers/macos/claude/settings.json`.
3. Verify without touching home:
   - `chezmoi apply --dry-run`;
   - a real apply to a scratch `--destination` (e.g. `/tmp/fakehome`) with `--persistent-state <temp file>`, `--exclude=scripts`, `--source ~/dotfiles-chezmoi`, and `--config <scratch config>` holding `[data]` `group` and `machine` values, so it never reads or writes the real `~/.config/chezmoi/chezmoi.toml`;
   - compare generated Claude `settings.json` with the live one using `jq -S`. The comparison matches the live `autoMode` once the untracked fragment from step 2 exists at `~/.config/dotfiles/claude.local.json`.
4. Add a `run_once_before_` migration script that:
   - on `wMac01` only, first: copies `/Volumes/External/Caches/claude` into the backup, removes the `~/.claude` link, creates a real `~/.claude` holding the external contents (run with no Claude session open). This comes first because the external directory holds the repo-pointing `settings.json`, `CLAUDE.md`, `skills`, `hooks` and `scripts` links, which the next step must then find under the new real `~/.claude`;
   - removes every symlink under `~` pointing into the dotfiles repo (the 22 `install.conf.yaml` links, including `~/.claude/skills`, `hooks`, `scripts`, `CLAUDE.md`, plus any created by the old `scripts/new-machine-setup.sh`'s `link_to_repo`; also leave its `*.bak` backups alone);
   - backs up any real file it replaces into `~/.dotfiles-migration-backup/<timestamp>/`;
   - writes a manifest of the old links before removing them;
   - runs identically on every Mac apart from the `wMac01` step.
5. Test the migration script in the sandbox with a symlinked `.claude` first, then on `sMac02` (push `v1-v2-migration` and check it out in that Mac's `~/dotfiles`) before cutting over `wMac01`.
6. Cutover (user runs, after reviewing the dry-run): merge the branch, update `~/dotfiles` in place, remove the worktree, run `install.sh`. The untracked fragment `~/.config/dotfiles/claude.local.json` is outside the repo and needs no copying.
7. After verifying the apply, the user manually deletes the migration backup and the old external Claude directory. Neither the script nor the apply deletes them.
8. Write steps 1-7 into the README.
9. Remove at migration: `functions/dotbot.sh`, the Dotbot `install` (replaced by `install.sh`), `install.conf.yaml`, `.gitmodules`, the `dotbot/` submodule, `scripts/omz-install.sh`.
10. Always pass `--exclude=scripts` on scratch applies (scripts act on the real `~`). `apply -n` does not run scripts.
11. Linux is out of scope: no Linux render or check. The Linux laptop is retired (its config is in `archive/`); leave any old Dotbot links on it alone.

## Classification

### `shared/`

- zsh: base `zshrc` (template), `p10k.zsh`, `auto-ls.zsh`.
- `functions/`: `claude-at`, `play-sound` (template), `template`, `run-script`, `log`, `notify`, `get_date`, `source-all-functions`, `dotapply`.
- Make `source-all-functions.sh` source the rendered copies in `~/.local/share/dotfiles/functions/`. Make `run_script` run `~/.local/share/dotfiles/scripts/`.
- `scripts/`: `update`, `init-archive`, `maintenance`, `list-commands`, `list-every-file`, `rm-DS_Store`, `init-env-vars`, `test`. `omz-install` is removed (see "Run scripts and externals"). `new-machine-setup` moves to the root as `install.sh` (see "`install.sh`").
- `prettier/`, VS Code base settings/keybindings/snippets/editorconfig. Repo-only (read from the checkout, never applied): `semgrep/` (the VS Code setting points at `~/dotfiles/semgrep/rules`) and `vscode/extensions.txt` (read by the runbook).
- Claude generics: `claude/CLAUDE.md` (a layered template; the worktree section moves to the work layer), hooks, scripts, `ccstatusline`, `run-tests.sh` (ignore each skill's `tests/` directory when applying), sound hooks (via `play-sound`).
- Generic skills: `clean-up`, `comment-keeper`, `debug-by-question`, `plan-condense`, `quiz-me`, `self-review-requirements`, `sync-branch`, `pre-commit`, plus those in "Skill changes".
- Keep dead tools (`archive/atom/` and the retired Linux desktop config) in top-level `archive/`; do not apply.

### `macos/`

- `iterm/brogrammer.itermcolors`. The repo has no iTerm2 hook scripts or profile files (see "Repo state"); the hooks call `~/.config/iterm2/cc-status`, which chezmoi does not manage.
- `hidden-files-hide.sh`, `hidden-files-show.sh`.
- `claude/settings.json` fragment registering the iTerm hooks, recovered from the live file (Migration step 2); no sound hooks.

### `work/Dimer_Health/`

- Claude settings fragment: Bedrock `env` (`CLAUDE_CODE_USE_BEDROCK`, `AWS_REGION`), Atlassian/Figma MCP permissions, `dimer-ts-utils` plugin, pnpm/flutter/dart/xcodebuild permissions. No `autoMode.environment` (it is in the untracked machine fragment).
- Skills: `parse-logs`, `set-up-worktree` and `find`.
- Claude instructions fragment `layers/work/Dimer_Health/claude/CLAUDE.md`: the "Git worktrees" section of `claude/CLAUDE.md` ("always use the `set-up-worktree` skill; never use `superpowers:using-git-worktrees`").
- zsh fragment: Flutter and Android SDK paths, pnpm, `AWS_PROFILE`. Model ARNs and `TICKET_BASE_URL` stay in the hand-edited `~/.zshrc.local`.
- VS Code override: `dart.flutterSdkPath`.
- Git fragment (personal GitHub identity, duplicated from personal).

### `work/Dimer_Health/wMac01/`

- Machine quirks only. Resolve Homebrew paths (ruby) at runtime in shared zsh code. Keep iTerm2 `cc-status` hooks in `macos/`.

### `personal/`

- `ssh/config` (now only `Host *`, the `pi` host and the `Include ~/.ssh/config.local` line; applied only on personal machines; remove the old symlink on the work Mac via the migration script), personal git fragment, `musescore/` (applied into `~/Archive/...`), personal-only Claude/zsh fragments if any.
- `backup` (`scripts/backup.sh`; user decision 2026-11-23: keep in `personal/`).

### `personal/sMac02/`

- Create `layers/personal/sMac02/` now, empty (add fragments only when something differs from the `personal` group).
- `scripts/new-machine-setup.sh` (the current runbook) has already run on this Mac. So it has Homebrew, `gh`, `node`, the MesloLGS NF font, Oh-My-Zsh/p10k/plugins and the VS Code extensions, plus the symlinks `link_to_repo` made (`~/.zshrc` and the VS Code settings, keybindings and snippets, with `*.bak` backups of anything it replaced). It is not a clean machine: the first chezmoi apply here goes through the migration script, which removes those links. This makes it the test of the migration script on a Mac with only the runbook's links (no Dotbot `./install` links, unless that was also run) before cutting over `wMac01`.
- Open question for the user: has `./install` (Dotbot) also been run on `sMac02`, and does it have a `~/.zshrc.local`? List its actual links with `find ~ -maxdepth 4 -type l -lname '*dotfiles*'` before the first apply.

## Cleanup (done; on `main` via PR #2 and merged into `v1-v2-migration`)

- Deleted: `cron/cron_test_0..4`, `screenshot.png` and its README embed, `assets/arc_reactor.png`, `iron_man_worktable.jpg`, `fox.png`, `musescore_logo.png`, `scripts/ocr_pdf.sh`, `scripts/install_all.sh`, `functions/keybase-alert.sh`, `functions/zz.sh`, `templates/zshrc.local`, nine old files under `docs/superpowers/plans` and `specs`.
- Renamed `functions/keybase-log.sh` → `functions/log.sh` (`run_script` and `scripts/backup.sh` call `log()`).
- Untracked `.claude/settings.local.json`.
- Archived (moved, not deleted) the Linux desktop config; `iterm/` replaced `theme-files/`; `install.conf.yaml` trimmed to the 22 macOS links.
- Added the new-machine runbook and the `.local` override includes (PR #1).
- Design docs and this plan stay untracked: `.gitignore` has `docs/superpowers` and `temp/*`. They exist only on disk (here and in `~/dotfiles`), so back them up yourself.
- Work on branch `v1-v2-migration`. `main` stays Dotbot-based until cutover.

## Skill changes

- `parse-logs` → `work/Dimer_Health/`. Read its scripts and docs against the sanitization rule; genericize or remove anything naming internal systems or describing the product's data. Keep doubtful parts out of git.
- `create-pr` → `shared/`. Replace the `MOB-123-` branch-name example with a neutral one.
- `update-pr-description` → `shared/`:
  - make `extract-tickets.sh` read the base URL from `TICKET_BASE_URL` (set by hand in `~/.zshrc.local` on work machines); emit ticket IDs without links when unset;
  - update `tests/test-skill.sh` to match (it hardcodes a stale Monday.com URL).
- `pr-comments-plan`, `pr-comments-address` → `shared/`. Replace `pnpm lint:fix` with "the repo's lint/fix command (found from CLAUDE.md or package.json)". Replace the `patient.service.ts` and `MOBI-562-...` example paths with neutral ones.
- `find` → `work/Dimer_Health/` (user decision: it delegates to `set-up-worktree`). Make `PROJECTS_DIR` in `find-branch.sh` overridable by env var (default `$HOME/Archive/04_Projects`).
- `investigate` → `shared/`. Replace the medication/patient worked example with a neutral one.
- `senior-pr-questions`, `after-pr-questions` → `shared/`.
- Learnings files (`quiz-learnings.md`, `boss-patterns.md`, `senior-pr-learnings.md`, `debug-learnings.md`): `quiz-learnings.md` and `boss-patterns.md` are already gitignored. Still tracked, so untrack (`git rm --cached`) and gitignore: `claude/skills/senior-pr-questions/senior-pr-learnings.md` and `claude/skills/debug-by-question/debug-learnings.md`. Make skills read all four only if they exist.
- Future (not part of this migration): consolidate the learnings files so every skill reads one single file instead of four. Until then keep the four files and the read-if-exists rule above.
- Never delete or overwrite learnings files on re-apply: do not use `exact_` on skill directories, or ignore those files explicitly.
- `pre-commit`: stays in `shared/`; no change.
- `set-up-worktree` → `work/Dimer_Health/` (user decision: work-only). Decided: `find` and the "Git worktrees" section of `claude/CLAUDE.md` move to the work layer with it, so personal machines never reference a missing skill. Builder task: make `claude/CLAUDE.md` a template in `home/` that renders the shared text, then appends `layers/<group>/claude/CLAUDE.md` and `layers/<group>/<machine>/claude/CLAUDE.md` if they exist (same skip-missing rule as the JSON fragments). The only other shared reference is in `claude/skills/pre-commit/SKILL.md` (line 149), which merely lists `set-up-worktree` and `find` by name in a table of skills it never asks about; harmless if the skills are absent, so no change needed. Also review the `claude/CLAUDE.md` scripts-table rows that talk about worktrees (`git-context.sh`, `sync-mcp-permissions.sh`); they are generic helpers and can stay.

## Sanitization (public repo `TheFirstQuestion/dotfiles`)

- Commit: ticket prefixes (MOB-, CUR-), skill logic, tool permissions, plugin names, the employer name in directory paths.
- Do not commit: internal domains/hostnames; descriptions of the product's data or integrations (especially patient/PHI data, third-party systems, production targets); infrastructure and repo-governance details (rulesets, deploy targets, protected environments); absolute paths revealing private project layout.
- Do not commit `autoMode.environment`. Keep it in the untracked machine fragment.
- When in doubt, keep the item out of git (an untracked local file) and flag it to the user.

## Git history audit

- Scan public history for committed secrets (tokens, API keys, `.env` content, Atlassian/AWS credentials) and Dimer-sensitive content. Report findings.
- Include: the Monday.com workspace URL in the deleted docs and `update-pr-description` tests; tracked learnings files; `.claude/settings.local.json`; autorandr `setup` files.
- Do not rewrite history or force-push.
- If a real secret is found, tell the user to rotate it.

## Builder tasks

- Pick a `refreshPeriod` for the oh-my-zsh, plugin and p10k externals in `.chezmoiexternal.toml` (they track the default branch; no pinning).
- Choose a test strategy beyond dry-run and scratch-destination renders.
- Reference Archive folder names from one place (chezmoi data read by templates). Write no new literal spaced paths.
- Once `chezmoi` is installed, confirm every chezmoi behavior this plan relies on and report any that differ: `--error-on-conflict` exists on `apply`; a template error aborts before any file is written, or the `run_before_` pre-check covers it; `.chezmoi.toml.tmpl` and `.chezmoiignore` are read from `home/` under `.chezmoiroot`; `refreshPeriod` and shallow `clone.args`/`pull.args` work on `git-repo` externals; the `jq` and `stat` functions behave as described. The jq program under "JSON merge" was checked only with jq 1.8.2 (objects deep-merge, arrays concatenate and de-duplicate, scalars take the later value), not with chezmoi's gojq.
- Check that oh-my-zsh's own auto-update (`zstyle ':omz:update' mode auto` in the zshrc) does not fight the chezmoi external (shallow clone, `--ff-only`). Do not change the setting without telling the user.
- `~/.config/iterm2/cc-status` is a symlink into the iTerm2 app bundle. Confirm what creates it. If iTerm2 does not create it on a new Mac, have `install.sh` create it (idempotent) so the macOS hooks do not fail.
- Do not commit unless the user asks. Write doc paragraphs as single long lines.

## Open decisions (assumptions made in the 2026-11-23 update; reverse any that are wrong)

- Per-OS layer directories vs the repo `CLAUDE.md` principle ("each file handles its own OS; no per-OS directories"). The plan keeps a `macos/` layer for macOS-only files (iTerm2 hooks, `iterm/`, hidden-files scripts) and uses `.chezmoiignore` for whole-file OS gating. If the principle wins, drop `macos/` and gate those files with `.chezmoiignore` alone, then update the principle text to describe layers.
- `sLaptop2` is retired: its config is archived, so it gets no layer and no entry anywhere.
- Root `install.sh` is the entry point (user decision); it is `scripts/new-machine-setup.sh` moved to the root, not a second script.
- Decided by the user 2026-11-23: no Bitwarden and no generated `~/.zshrc.local`. The `.local` files exist to hold untracked secrets, so they stay hand-edited and chezmoi never writes them.
- Machine-local `additionalDirectories` and the full `autoMode.environment` go in the untracked `~/.config/dotfiles/claude.local.json` fragment (outside the repo, like `~/.zshrc.local`), not in a tracked `layers/` file and not in a gitignored file inside the repo, because the repo is public and those paths and that text reveal private details. Reverse this if committing them is acceptable.
- Bedrock `env` (`CLAUDE_CODE_USE_BEDROCK`, `AWS_REGION`) stays in the Claude work fragment, mirroring the live `settings.json`; `AWS_PROFILE` goes in `zsh/env.zsh`.

## Needs updating / confirming

Running list; tick off or delete items as they are settled.

- Move `find` and the "Git worktrees" section of `claude/CLAUDE.md` to the work layer, and turn `claude/CLAUDE.md` into a layered template (see "Skill changes").
- Create the git and ssh templates (`home/dot_gitconfig.tmpl`, `home/private_dot_ssh/private_config.tmpl`) and the git identity fragments under `layers/personal/git/` and `layers/work/Dimer_Health/git/`; they need `home/.chezmoi.toml.tmpl` (for `group` and `machine`) and the ssh gate in `.chezmoiignore` first.
- Move `scripts/new-machine-setup.sh` to the root `install.sh` and update repo `CLAUDE.md` and `README.md` (new command, "new setup steps belong in it" line); fix the script's repo-location logic for its new place.
- Bring the design spec (`docs/superpowers/specs/2026-11-06-work-personal-layers-design.md`) in line with this plan: it still describes Bitwarden, the generated `~/.zshrc.local`, the placeholder switch and the headless template handling (all removed), plus the abort-on-missing-item failure policy, the `v1_last`/`v1_cutover` rollback, and the old `install.sh` wording.
- Future: consolidate the four learnings files (`quiz-learnings.md`, `boss-patterns.md`, `senior-pr-learnings.md`, `debug-learnings.md`) into one file that all the skills read. Decide the file's name and location (it must stay untracked and survive re-apply), then update each skill.
- Settle the Open decisions above (the `macos/` layer vs the repo `CLAUDE.md` per-OS principle).

## Out of scope

- Renaming `~/Archive` folders to remove spaces (separate project). Spaced names appear in: musescore links (`07 Application Files/MuseScore4/...`), p10k shortcuts (`01 Personal`, `02 School`, `03 Work`), `vscode/settings.json` (`dart.flutterSdkPath`), `scripts/init-archive.sh`, `scripts/backup.sh`, `scripts/maintenance.sh`, `zsh/zshrc` (the Flutter `path+=` line), the apply-time Archive check.
- Linux support in general: layers, apply paths, `install.sh` Linux branch (stub only), and any chezmoi management of the retired Linux laptop.
