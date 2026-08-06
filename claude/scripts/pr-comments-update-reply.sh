#!/bin/bash
# Updates the body of an existing pending reply in the progress file.
# Usage: pr-comments-update-reply.sh <progress-file> <comment-id> <new-body>
set -euo pipefail

progress_file="$1"
comment_id="$2"
new_body="$3"

if [[ ! -f "$progress_file" ]]; then
  echo "Error: progress file not found: $progress_file" >&2
  exit 1
fi

# Check the entry exists
exists=$(jq --argjson id "$comment_id" '.pending_replies | map(select(.comment_id == $id)) | length' "$progress_file")
if [[ "$exists" -eq 0 ]]; then
  echo "Error: no pending reply found for comment $comment_id" >&2
  exit 1
fi

updated=$(jq \
  --argjson id "$comment_id" \
  --arg body "$new_body" \
  '.pending_replies = [.pending_replies[] | if .comment_id == $id then .body = $body else . end]' \
  "$progress_file")

echo "$updated" > "$progress_file"
echo "Updated reply for comment $comment_id"
