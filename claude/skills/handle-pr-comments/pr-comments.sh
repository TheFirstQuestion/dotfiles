#!/usr/bin/env bash
# Fetch and pre-process all data needed by the handle-pr-comments skill.
# Usage: pr-comments [PR-number-or-URL]
#
# Output JSON keys:
#   pr               — PR metadata
#   comment_queue    — ordered array of root inline comments, grouped by file,
#                      each with: id, path, line, outdated, already_replied,
#                      reviewer, body, diff_hunk, thread_replies[]
#                      (thread_replies trimmed to: id, reviewer, body only)
#   actionable_reviews — review-level comments worth actioning
#                        (PR overview summaries filtered out)
#   ci               — CI check results
#   merge            — { mergeable, mergeStateStatus }

set -euo pipefail

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

# ---------- fetch everything ----------
pr_raw=$(gh pr view "$number" -R "$repo" \
  --json number,url,title,headRefName,baseRefName,author,state,statusCheckRollup,mergeable,mergeStateStatus)

inline_json=$(gh api "repos/$repo/pulls/$number/comments" --paginate)

reviews_json=$(gh api "repos/$repo/pulls/$number/reviews" --paginate)

# ---------- process and combine ----------
jq -n \
  --argjson pr_raw  "$pr_raw" \
  --argjson inline  "$inline_json" \
  --argjson reviews "$reviews_json" \
  '
  ($pr_raw | {number, url, title, headRefName, baseRefName, author, state}) as $pr |
  ($pr_raw.statusCheckRollup // [])                                          as $ci |
  ($pr_raw | {mergeable, mergeStateStatus})                                  as $merge |

  # Split inline comments into roots and replies
  ($inline | map(select(.in_reply_to_id == null))) as $roots |
  ($inline | map(select(.in_reply_to_id != null))) as $replies |

  # Build reply_map: root comment id (string) -> array of replies
  (reduce $replies[] as $r (
    {};
    . + { ($r.in_reply_to_id | tostring): ((.[$r.in_reply_to_id | tostring] // []) + [$r]) }
  )) as $reply_map |

  ($roots | sort_by(.path) | map(
    . as $root |
    ($reply_map[$root.id | tostring] // []) as $replies |
    {
      id:              $root.id,
      path:            $root.path,
      # .line is the current line; falls back to .original_line for outdated comments
      line:            ($root.line // $root.original_line),
      outdated:        ($root.position == null),
      already_replied: ($replies | length > 0),
      reviewer:        $root.user.login,
      body:            $root.body,
      diff_hunk:       $root.diff_hunk,
      thread_replies:  ($replies | map({id: .id, reviewer: .user.login, body: .body}))
    }
  )) as $comment_queue |

  # Actionable reviews: CHANGES_REQUESTED or COMMENTED with non-empty body,
  # excluding PR overview summaries (Copilot boilerplate starting with "## Pull request overview")
  ($reviews | map(select(
    (.body != null and .body != "") and
    (.state == "CHANGES_REQUESTED" or .state == "COMMENTED") and
    (.body | startswith("## Pull request overview") | not)
  )) | map({
    id:       .id,
    reviewer: .user.login,
    state:    .state,
    body:     .body
  })) as $actionable_reviews |

  {
    pr:                 $pr,
    comment_queue:      $comment_queue,
    actionable_reviews: $actionable_reviews,
    ci:                 $ci,
    merge:              $merge
  }
  '
