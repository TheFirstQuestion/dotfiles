#!/usr/bin/env bash
# Blocks `cd <path> && git <cmd>` patterns and suggests git -C instead.

COMMAND=$(jq -r '.tool_input.command // ""')

if echo "$COMMAND" | grep -qE 'cd .+ && git |cd .+; git '; then
  # Extract the path and git command for a helpful suggestion
  PATH_PART=$(echo "$COMMAND" | grep -oE 'cd [^&;]+' | head -1 | sed 's/^cd //' | xargs)
  GIT_PART=$(echo "$COMMAND" | grep -oE '(&&|;) *git .+' | head -1 | sed 's/^[&; ]*//')
  SUGGESTION="git -C ${PATH_PART} ${GIT_PART#git }"

  jq -n \
    --arg suggestion "$SUGGESTION" \
    '{
      "decision": "block",
      "reason": ("Use git -C instead of cd && git — cd triggers a permission prompt.\nSuggested: " + $suggestion)
    }'
  exit 0
fi
