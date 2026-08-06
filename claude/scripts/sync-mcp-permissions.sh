#!/usr/bin/env bash
# Merges mcp__* allow entries from user-scope settings into a project .claude/settings.local.json.
# Usage: sync-mcp-permissions.sh <project-root>
# Creates .claude/settings.local.json if absent. Idempotent — skips entries already present.

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"
USER_SETTINGS="$HOME/.claude/settings.json"
PROJECT_SETTINGS="$PROJECT_ROOT/.claude/settings.local.json"

if [ ! -f "$USER_SETTINGS" ]; then
  echo "sync-mcp-permissions: user settings not found at $USER_SETTINGS" >&2
  exit 1
fi

# Extract mcp__* allow entries from user settings
MCP_ALLOWS=$(jq -r '.permissions.allow[]? | select(startswith("mcp__"))' "$USER_SETTINGS")

if [ -z "$MCP_ALLOWS" ]; then
  echo "sync-mcp-permissions: no mcp__* allow entries found in user settings, nothing to do"
  exit 0
fi

mkdir -p "$PROJECT_ROOT/.claude"

# Create minimal settings.json if absent
if [ ! -f "$PROJECT_SETTINGS" ]; then
  echo '{"permissions":{"allow":[]}}' > "$PROJECT_SETTINGS"
fi

# Merge each mcp__* entry into project allow list if not already present
ADDED=0
while IFS= read -r entry; do
  ALREADY=$(jq -r --arg e "$entry" '.permissions.allow[]? | select(. == $e)' "$PROJECT_SETTINGS")
  if [ -z "$ALREADY" ]; then
    jq --arg e "$entry" '.permissions.allow += [$e]' "$PROJECT_SETTINGS" > "$PROJECT_SETTINGS.tmp"
    mv "$PROJECT_SETTINGS.tmp" "$PROJECT_SETTINGS"
    echo "  + $entry"
    ADDED=$((ADDED + 1))
  fi
done <<< "$MCP_ALLOWS"

if [ "$ADDED" -eq 0 ]; then
  echo "sync-mcp-permissions: all mcp__* entries already present in $PROJECT_SETTINGS"
else
  echo "sync-mcp-permissions: added $ADDED entr$([ $ADDED -eq 1 ] && echo 'y' || echo 'ies') to $PROJECT_SETTINGS"
fi
