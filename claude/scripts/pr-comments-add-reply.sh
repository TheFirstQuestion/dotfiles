#!/bin/bash
# Appends a pending reply to the PR comments progress file.
# Usage: pr-comments-add-reply.sh <progress-file> <comment-id> <reply-type> <body>
#   reply-type: "inline" or "review"
# Adds comment-id to completed[] and the reply object to pending_replies[].
set -euo pipefail

progress_file="$1"
comment_id="$2"
reply_type="$3"
body="$4"

if [[ ! -f "$progress_file" ]]; then
  echo "Error: progress file not found: $progress_file" >&2
  exit 1
fi

updated=$(jq \
  --argjson id "$comment_id" \
  --arg type "$reply_type" \
  --arg body "$body" \
  '.completed += [$id] | .pending_replies += [{comment_id: $id, reply_type: $type, body: $body}]' \
  "$progress_file")

echo "$updated" > "$progress_file"
echo "Recorded reply for comment $comment_id"
