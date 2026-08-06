#!/usr/bin/env bash
# PreToolUse hook — blocks git commit unless pre-commit skill has been run
# against the exact current working tree state.
#
# The pre-commit skill writes a hash of `git diff HEAD` + untracked file names
# to /tmp/pre-commit-gate-<repo-slug>.hash. This script recomputes the same hash
# and compares. Staging files does NOT change the hash; adding new untracked files does.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only gate actual commits (not --amend rewrites of existing commits, etc.)
# Also match calls to git-commit.sh, which internally runs git commit.
if [[ "$COMMAND" != git\ commit* && "$COMMAND" != *git-commit.sh* ]]; then
  exit 0
fi

# When the command starts with "cd <path> && ...", use that path — the shell's
# .cwd may point to a different worktree if Claude reset between tool calls.
if [[ "$COMMAND" =~ ^cd[[:space:]]+([^[:space:]&]+) ]]; then
  CWD="${BASH_REMATCH[1]}"
else
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
  if [[ -z "$CWD" ]]; then
    CWD=$(pwd)
  fi
fi

# Derive repo slug from the git root directory name
REPO_SLUG=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null | xargs basename | tr '/' '-')
HASH_FILE="/tmp/pre-commit-gate-${REPO_SLUG}.hash"

# Compute current tree hash — must match the formula in pre-commit/SKILL.md Step 5
CURRENT_HASH=$( (git -C "$CWD" diff HEAD 2>/dev/null; git -C "$CWD" ls-files --others --exclude-standard 2>/dev/null) | shasum -a 256 | cut -d' ' -f1 )

if [[ ! -f "$HASH_FILE" ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Claude must run the /pre-commit skill before committing."
    }
  }'
  exit 0
fi

SAVED_HASH=$(cat "$HASH_FILE")

if [[ "$CURRENT_HASH" != "$SAVED_HASH" ]]; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Working tree changed since pre-commit ran. Run /pre-commit again."
    }
  }'
  exit 0
fi

# Hash matches — allow the commit. The hash is consumed by post-commit-gate.sh
# (PostToolUse) after the commit actually runs, so a rejected permission prompt
# doesn't burn the hash.
exit 0
