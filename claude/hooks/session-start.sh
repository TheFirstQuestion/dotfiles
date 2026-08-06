#!/usr/bin/env bash
# SessionStart hook — prints working directory, branch, and PR link.

CWD=$(pwd)
echo "cwd: $CWD"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [[ -n "$BRANCH" ]]; then
  echo "branch: $BRANCH"
  PR=$(gh pr view --json number,url,title --jq '"#\(.number) \(.url) — \(.title)"' 2>/dev/null || true)
  if [[ -n "$PR" ]]; then
    echo "pr: $PR"
  else
    echo "pr: none"
  fi
else
  echo "(not a git repo)"
fi
