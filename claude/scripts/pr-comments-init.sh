#!/bin/bash
# Initializes a PR comments progress file.
# Usage: pr-comments-init.sh <progress-file> <pr-number> <repo> <total>
set -euo pipefail

progress_file="$1"
pr_number="$2"
repo="$3"
total="$4"

jq -n \
  --argjson pr_number "$pr_number" \
  --arg repo "$repo" \
  --argjson total "$total" \
  '{pr_number: $pr_number, repo: $repo, total: $total, completed: [], pending_replies: []}' \
  > "$progress_file"

echo "Progress file created: $progress_file"
