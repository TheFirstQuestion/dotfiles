#!/bin/bash
# Add a directory to permissions.additionalDirectories in ~/.claude/settings.local.json.
# Idempotent — skips if already present. settings.local.json is gitignored so
# project-specific/work paths never land in the public dotfiles repo.
set -euo pipefail

DIR="${1:-$(pwd)}"
SETTINGS=$(realpath ~/.claude/settings.local.json)

# Create the file with minimal structure if it doesn't exist
if [[ ! -f "$SETTINGS" ]]; then
  echo '{"permissions":{"additionalDirectories":[]}}' > "$SETTINGS"
fi

jq --arg dir "$DIR" '
  .permissions.additionalDirectories //= [] |
  if (.permissions.additionalDirectories | index($dir)) != null
  then .
  else .permissions.additionalDirectories += [$dir]
  end
' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"

echo "Allowed: $DIR"
