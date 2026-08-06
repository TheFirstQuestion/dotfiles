#!/usr/bin/env bash
# PreToolUse hook — runs git-security-scan before any git push.
# Blocks the push if potential secrets are found in the diff vs remote.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only gate push commands
[[ "$COMMAND" != git\ push* ]] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && CWD=$(pwd)

# Get the remote tracking branch to diff against
UPSTREAM=$(git -C "$CWD" rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)

if [[ -n "$UPSTREAM" ]]; then
  SCAN_OUTPUT=$(~/.claude/scripts/git-security-scan.sh "$UPSTREAM..HEAD" 2>&1)
else
  # No upstream yet — scan everything not on main
  SCAN_OUTPUT=$(~/.claude/scripts/git-security-scan.sh "origin/main..HEAD" 2>&1)
fi

SCAN_EXIT=$?

if [[ "$SCAN_EXIT" -ne 0 ]]; then
  REASON=$(echo "$SCAN_OUTPUT" | tail -n +2 | head -20 | tr '\n' ' ')
  jq -n --arg reason "Security scan failed before push: $REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
fi

exit 0
