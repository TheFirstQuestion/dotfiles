#!/usr/bin/env bash
# Extract ticket IDs from a PR and return them as a JSON array.
# Usage: extract-tickets.sh [PR-number-or-URL]
#
# Output: JSON array of {id, url} objects, e.g.:
#   [{"id":"MOB-123","url":"https://dimerhealth-cast.monday.com/item/MOB-123"}]
# Returns [] if no tickets found.
# On error: prints {"error":"..."} to stderr and exits non-zero.

set -euo pipefail

MONDAY_BASE="https://dimerhealth-cast.monday.com/item"

# ---------- resolve PR number and repo ----------
repo=""
if [[ $# -gt 0 ]]; then
  arg="$1"
  number="${arg##*/}"
  if [[ "$arg" =~ github\.com/([^/]+/[^/]+)/pull/ ]]; then
    repo="${BASH_REMATCH[1]}"
  fi
else
  number=$(gh pr view --json number -q '.number' 2>/dev/null || true)
  if [[ -z "$number" ]]; then
    echo '{"error":"No PR found. Run from a branch with an open PR, or pass a PR number."}' >&2
    exit 1
  fi
fi
if [[ -z "$repo" ]]; then
  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
fi

# ---------- fetch text sources ----------
pr_json=$(gh pr view "$number" -R "$repo" \
  --json title,body,headRefName,commits)

branch=$(echo "$pr_json" | jq -r '.headRefName')
title=$(echo "$pr_json"  | jq -r '.title')
body=$(echo "$pr_json"   | jq -r '.body')
commits=$(echo "$pr_json" | jq -r '.commits[].messageHeadline')

# ---------- extract, normalize, deduplicate ----------
tickets=$(printf '%s\n%s\n%s\n%s\n' "$branch" "$title" "$body" "$commits" \
  | grep -oE '[A-Za-z]+-[0-9]+' \
  | awk -F'-' '{printf "%s-%s\n", toupper($1), $2}' \
  | sort -u)

# ---------- emit JSON ----------
if [[ -z "$tickets" ]]; then
  echo '[]'
  exit 0
fi

echo "$tickets" | jq -R -s \
  --arg base "$MONDAY_BASE" \
  'split("\n") | map(select(length > 0)) | map({id: ., url: ($base + "/" + .)})'
