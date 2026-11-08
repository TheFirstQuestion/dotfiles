#!/usr/bin/env bash
# Launcher for the Claude Code status line (reads the session JSON on stdin). Resolves ccstatusline per machine so ~/.claude/settings.json stays portable.
# Resolution order:
#   1. $CCSTATUSLINE_BIN (explicit per-machine override, e.g. set in your shell profile or settings.json "env")
#   2. ccstatusline on PATH
#   3. pnpm global bin dirs ($PNPM_HOME, macOS, Linux defaults)
#   4. npx, run from $HOME because npm aborts with EBADDEVENGINES inside pnpm-only repos

if [ -n "$CCSTATUSLINE_BIN" ] && [ -x "$CCSTATUSLINE_BIN" ]; then
  exec "$CCSTATUSLINE_BIN"
fi

if command -v ccstatusline >/dev/null 2>&1; then
  exec ccstatusline
fi

for candidate in \
  "${PNPM_HOME:+$PNPM_HOME/bin/ccstatusline}" \
  "${PNPM_HOME:+$PNPM_HOME/ccstatusline}" \
  "$HOME/Library/pnpm/bin/ccstatusline" \
  "$HOME/Library/pnpm/ccstatusline" \
  "$HOME/.local/share/pnpm/bin/ccstatusline" \
  "$HOME/.local/share/pnpm/ccstatusline"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    exec "$candidate"
  fi
done

# Pinned (not @latest) so a compromised or broken npm release can't run on every status-line refresh; bump deliberately after checking the release.
cd "$HOME" && exec npx -y ccstatusline@2.2.33
