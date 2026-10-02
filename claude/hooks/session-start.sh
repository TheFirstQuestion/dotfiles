#!/usr/bin/env bash
# SessionStart hook — reports working directory, branch, and PR link as context,
# and sets the session title to "<repo>:<ticket>" (falling back to "<repo>:<branch>").

CWD=$(pwd)
CONTEXT="cwd: $CWD"
SESSION_TITLE=""

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [[ -n "$BRANCH" ]]; then
  CONTEXT="$CONTEXT
branch: $BRANCH"

  PR=$(gh pr view --json number,url,title --jq '"#\(.number) \(.url) — \(.title)"' 2>/dev/null || true)
  if [[ -n "$PR" ]]; then
    CONTEXT="$CONTEXT
pr: $PR"
  else
    CONTEXT="$CONTEXT
pr: none"
  fi

  REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
  if [[ -n "$REMOTE_URL" ]]; then
    REPO_NAME=$(basename -s .git "$REMOTE_URL")
  else
    TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null || true)
    REPO_NAME=$(basename "$TOPLEVEL")
  fi

  # Ticket IDs look like MOBI-123 or CURA-1234; grab the first match from the branch name.
  TICKET=$(echo "$BRANCH" | grep -oE '[A-Za-z]+-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]')

  if [[ -n "$REPO_NAME" ]]; then
    if [[ -n "$TICKET" ]]; then
      SESSION_TITLE="$REPO_NAME:$TICKET"
    else
      SESSION_TITLE="$REPO_NAME:$BRANCH"
    fi
  fi
else
  CONTEXT="$CONTEXT
(not a git repo)"
fi

jq -n --arg ctx "$CONTEXT" --arg title "$SESSION_TITLE" '
  {
    hookSpecificOutput: (
      {hookEventName: "SessionStart", additionalContext: $ctx}
      + (if $title != "" then {sessionTitle: $title} else {} end)
    )
  }
'
