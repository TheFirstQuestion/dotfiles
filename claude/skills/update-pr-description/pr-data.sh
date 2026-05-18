#!/usr/bin/env bash
# Fetch all data needed by update-pr-description in a single call.
# Usage: pr-data.sh [PR-number-or-URL]
#
# stdout:   JSON object with keys: pr, commits, template, stacked_prs, diff_path
# diff:     written to /tmp/pr-data-<repo-slug>-<number>.diff
# on error: {"error":"..."} on stderr, exit non-zero

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

# ---------- validate number is numeric ----------
if ! [[ "$number" =~ ^[0-9]+$ ]]; then
  echo '{"error":"Invalid PR number: '"$number"'"}' >&2
  exit 1
fi

repo_slug="${repo//\//-}"
diff_path="/tmp/pr-data-${repo_slug}-${number}.diff"

# ---------- parallel fetches ----------
tmp_pr=$(mktemp)
tmp_list=$(mktemp)
trap 'rm -f "$tmp_pr" "$tmp_list"' EXIT

gh pr view "$number" -R "$repo" \
  --json number,url,title,body,headRefName,baseRefName,author,commits \
  > "$tmp_pr" &
pid_pr=$!

gh pr list -R "$repo" \
  --json number,url,title,headRefName,baseRefName,body \
  --state open \
  > "$tmp_list" &
pid_list=$!

gh pr diff "$number" -R "$repo" > "$diff_path" &
pid_diff=$!

wait "$pid_pr" "$pid_list" "$pid_diff"

# ---------- validate fetch results ----------
if ! jq empty "$tmp_pr" 2>/dev/null; then
  echo '{"error":"Failed to fetch PR data. Check that the PR number and repo are correct."}' >&2
  exit 1
fi
if ! jq empty "$tmp_list" 2>/dev/null; then
  echo '{"error":"Failed to fetch open PR list."}' >&2
  exit 1
fi

# ---------- template detection ----------
template_content="null"
for tmpl_path in \
  ".github/PULL_REQUEST_TEMPLATE.md" \
  ".github/pull_request_template.md" \
  "docs/pull_request_template.md"; do
  if [[ -f "$tmpl_path" ]]; then
    template_content=$(jq -Rs '.' < "$tmpl_path")
    break
  fi
done

# ---------- assemble JSON ----------
jq -n \
  --argjson pr_raw    "$(cat "$tmp_pr")" \
  --argjson all_prs   "$(cat "$tmp_list")" \
  --argjson template  "$template_content" \
  --arg     diff_path "$diff_path" \
  '
  ($pr_raw | {
    number, url, title, body, headRefName, baseRefName,
    author: .author.login
  }) as $pr |

  ($pr_raw.commits | map(.messageHeadline)) as $commits |

  ($all_prs | map(select(.number != $pr.number)) | map(
    . as $o |
    if   $o.baseRefName == $pr.headRefName then
      {number: $o.number, url: $o.url, title: $o.title,
       headRefName: $o.headRefName, baseRefName: $o.baseRefName,
       relationship: "child"}
    elif $o.headRefName == $pr.baseRefName then
      {number: $o.number, url: $o.url, title: $o.title,
       headRefName: $o.headRefName, baseRefName: $o.baseRefName,
       relationship: "parent"}
    elif (($o.body // "") | test("#" + ($pr.number | tostring) + "\\b|" + $pr.headRefName; "g"))
      or (($o.title // "") | test("#" + ($pr.number | tostring) + "\\b|" + $pr.headRefName; "g")) then
      {number: $o.number, url: $o.url, title: $o.title,
       headRefName: $o.headRefName, baseRefName: $o.baseRefName,
       relationship: "mentioned"}
    else
      empty
    end
  )) as $stacked_prs |

  {
    pr:          $pr,
    commits:     $commits,
    template:    $template,
    stacked_prs: $stacked_prs,
    diff_path:   $diff_path
  }
  '
