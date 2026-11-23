# Local overrides

Each file below is machine-only and not tracked in git. If it is missing, nothing breaks.

| Local file | Shared file | Which wins on conflict |
| ------------ | ------------- | ------------------------ |
| `~/.ssh/config.local` | `ssh/config` (`Include` at top) | Local wins |
| `~/.zshrc.local` | `zsh/zshrc` (`source` under the "Machine-specific environment variables" comment) | Last definition wins: local overrides everything above the `source` line, anything below it overrides local |
| `~/.gitconfig.local` | `git/gitconfig` (`[include]` at end) | Local wins |
| `~/.claude/settings.local.json` | `claude/settings.json` | Local wins for scalar settings; arrays such as permissions are merged |
