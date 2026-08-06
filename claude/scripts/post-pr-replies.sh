#!/bin/bash
# Posts all pending replies from a PR comments progress file.
# Usage: post-pr-replies.sh <progress-file>
# Reads pending_replies[] and posts each via gh api, then prints a summary.
# Exit code 1 if any post fails.
set -euo pipefail

progress_file="$1"

if [[ ! -f "$progress_file" ]]; then
  echo "Error: progress file not found: $progress_file" >&2
  exit 1
fi

repo=$(jq -r '.repo' "$progress_file")
pr_number=$(jq -r '.pr_number' "$progress_file")
reply_count=$(jq '.pending_replies | length' "$progress_file")

if [[ "$reply_count" -eq 0 ]]; then
  echo "No pending replies to post."
  exit 0
fi

echo "Posting $reply_count replies to $repo#$pr_number..."

failed=0

for i in $(seq 0 $((reply_count - 1))); do
  comment_id=$(jq -r ".pending_replies[$i].comment_id" "$progress_file")
  reply_type=$(jq -r ".pending_replies[$i].reply_type" "$progress_file")
  body=$(jq -r ".pending_replies[$i].body" "$progress_file")

  if [[ "$reply_type" == "inline" ]]; then
    gh api "repos/$repo/pulls/$pr_number/comments/$comment_id/replies" \
      -f body="$body" > /dev/null \
      && echo "  [$((i+1))/$reply_count] posted inline reply to comment $comment_id" \
      || { echo "  [$((i+1))/$reply_count] FAILED inline reply to comment $comment_id" >&2; failed=1; }
  else
    gh api "repos/$repo/pulls/$pr_number/comments/$comment_id/replies" \
      -f body="$body" > /dev/null \
      && echo "  [$((i+1))/$reply_count] posted review reply to comment $comment_id" \
      || { echo "  [$((i+1))/$reply_count] FAILED review reply to comment $comment_id" >&2; failed=1; }
  fi
done

if [[ "$failed" -eq 1 ]]; then
  echo "Some replies failed — check output above."
  exit 1
fi

echo "All replies posted successfully."
