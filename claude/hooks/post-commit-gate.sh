#!/usr/bin/env bash
# PostToolUse hook — after a successful git commit, consume the pre-commit gate hash
# so the next commit requires a fresh /pre-commit run.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on commit commands
if [[ "$COMMAND" != git\ commit* && "$COMMAND" != *git-commit.sh* ]]; then
  exit 0
fi

# Only consume on success
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exitCode // 0')
if [[ "$EXIT_CODE" != "0" ]]; then
  exit 0
fi

# Derive repo slug the same way the PreToolUse hook does
if [[ "$COMMAND" =~ ^cd[[:space:]]+([^[:space:]&]+) ]]; then
  CWD="${BASH_REMATCH[1]}"
else
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  if [[ -z "$CWD" ]]; then
    CWD=$(pwd)
  fi
fi

REPO_SLUG=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null | xargs basename | tr '/' '-')
HASH_FILE="/tmp/pre-commit-gate-${REPO_SLUG}.hash"

rm -f "$HASH_FILE"
exit 0
