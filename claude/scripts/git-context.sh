#!/bin/bash
# Print git context: GIT_DIR, GIT_COMMON_DIR, current branch, and worktree status.
# GIT_DIR != GIT_COMMON means you are in a linked worktree.
set -euo pipefail

GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
SUPERPROJECT=$(git rev-parse --show-superproject-working-tree 2>/dev/null || true)

echo "GIT_DIR=$GIT_DIR"
echo "GIT_COMMON=$GIT_COMMON"
echo "branch=$BRANCH"

if [[ "$GIT_DIR" != "$GIT_COMMON" && -z "$SUPERPROJECT" ]]; then
  echo "context=worktree"
elif [[ -n "$SUPERPROJECT" ]]; then
  echo "context=submodule"
else
  echo "context=main"
fi
