#!/usr/bin/env bash
# Usage: clean-up-gather-state.sh <repo-path>
# Prints worktree list, branches with upstream tracking, last-commit dates, and HEAD
# for the given repo. Used by the clean-up skill (Step 1 gather phase).
set -euo pipefail

repo="${1:?Usage: clean-up-gather-state.sh <repo-path>}"

echo "---WORKTREES---"
git -C "$repo" worktree list --porcelain

echo "---BRANCHES---"
git -C "$repo" branch --format='%(refname:short) %(upstream:short) %(upstream:track)'

echo "---DATES---"
git -C "$repo" for-each-ref --format='%(refname:short) %(committerdate:iso8601)' refs/heads/

echo "---HEAD---"
git -C "$repo" rev-parse --abbrev-ref HEAD

echo "---REMOTE---"
git -C "$repo" remote get-url origin 2>/dev/null || echo "NO_REMOTE"
