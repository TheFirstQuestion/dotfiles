#!/usr/bin/env bash
# PreToolUse hook — blocks Write/Edit targeting .env files.
# .env files contain credentials and should never be written by Claude.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0

BASENAME=$(basename "$FILE_PATH")

if [[ "$BASENAME" == .env || "$BASENAME" == .env.* || "$BASENAME" == *.env ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Writing .env files is blocked. Edit the file manually or ask the user to make the change."
    }
  }'
fi

exit 0
