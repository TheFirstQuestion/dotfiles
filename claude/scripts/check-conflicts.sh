#!/usr/bin/env bash
# check-conflicts.sh [base-branch]
# Checks whether the current branch has merge conflicts with the base branch.
# Defaults to origin/main if no base branch is given.
# Exits 0 if no conflicts, 1 if conflicts found.

BASE="${1:-origin/main}"

MERGE_BASE=$(git merge-base HEAD "$BASE" 2>/dev/null)
if [[ -z "$MERGE_BASE" ]]; then
  echo "Could not find merge base with $BASE — is the remote fetched?"
  exit 1
fi

RESULT=$(git merge-tree "$MERGE_BASE" HEAD "$BASE" 2>&1)
# Match only actual git conflict markers, not the word "conflict" in source code
CONFLICTS=$(echo "$RESULT" | grep -E "^(\+)?(<<<<<<<|=======|>>>>>>>)" || true)

if [[ -n "$CONFLICTS" ]]; then
  echo "Conflicts found with $BASE:"
  echo "$CONFLICTS"
  exit 1
else
  echo "No conflicts with $BASE"
  exit 0
fi
