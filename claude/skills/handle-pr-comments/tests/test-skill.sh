#!/usr/bin/env bash
# Offline tests for pr-comments.sh jq transform logic.
# No gh invocations — tests pure jq pipeline logic with fixture data.

PASS=0; FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  ✓ $desc"; ((PASS++))
  else
    echo "  ✗ $desc"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    ((FAIL++))
  fi
}

assert_json_eq() {
  local desc="$1"
  local expected actual
  expected=$(echo "$2" | jq -c .)
  actual=$(echo "$3" | jq -c .)
  assert_eq "$desc" "$expected" "$actual"
}

echo "pr-comments.sh"

# Helper: run the comment_queue jq transform against fixture inline data
comment_queue() {
  local inline_json="$1"
  jq -n \
    --argjson inline "$inline_json" \
    '
    ($inline | map(select(.in_reply_to_id == null))) as $roots |
    ($inline | map(select(.in_reply_to_id != null))) as $replies |
    (reduce $replies[] as $r (
      {};
      . + { ($r.in_reply_to_id | tostring): ((.[$r.in_reply_to_id | tostring] // []) + [$r]) }
    )) as $reply_map |
    ($roots | sort_by(.path) | map(
      . as $root |
      ($reply_map[$root.id | tostring] // []) as $thread_replies |
      {
        id:              $root.id,
        path:            $root.path,
        line:            ($root.line // $root.original_line),
        outdated:        ($root.position == null),
        already_replied: ($thread_replies | length > 0),
        reviewer:        $root.user.login,
        body:            $root.body,
        diff_hunk:       $root.diff_hunk,
        thread_replies:  ($thread_replies | map({id: .id, reviewer: .user.login, body: .body}))
      }
    ))
    '
}

# Helper: run the actionable_reviews jq transform
actionable_reviews() {
  local reviews_json="$1"
  jq -n \
    --argjson reviews "$reviews_json" \
    '
    $reviews | map(select(
      (.body != null and .body != "") and
      (.state == "CHANGES_REQUESTED" or .state == "COMMENTED") and
      (.body | startswith("## Pull request overview") | not)
    )) | map({id: .id, reviewer: .user.login, state: .state, body: .body})
    '
}

# ---------- comment_queue tests ----------

root_only='[{
  "id": 1, "path": "src/foo.ts", "line": 10, "original_line": 10,
  "position": 5, "in_reply_to_id": null,
  "user": {"login": "alice"}, "body": "fix this", "diff_hunk": "@@ ..."
}]'

assert_eq "root comment appears in queue" \
  "1" \
  "$(comment_queue "$root_only" | jq 'length')"

assert_eq "root comment id is correct" \
  "1" \
  "$(comment_queue "$root_only" | jq '.[0].id')"

with_reply='[
  {"id": 1, "path": "src/foo.ts", "line": 10, "original_line": 10,
   "position": 5, "in_reply_to_id": null,
   "user": {"login": "alice"}, "body": "fix this", "diff_hunk": "@@ ..."},
  {"id": 2, "path": "src/foo.ts", "line": 10, "original_line": 10,
   "position": 5, "in_reply_to_id": 1,
   "user": {"login": "bob"}, "body": "done", "diff_hunk": "@@ ..."}
]'

assert_eq "reply comment does not appear as root" \
  "1" \
  "$(comment_queue "$with_reply" | jq 'length')"

assert_eq "already_replied true when reply exists" \
  "true" \
  "$(comment_queue "$with_reply" | jq '.[0].already_replied')"

assert_eq "already_replied false when no reply" \
  "false" \
  "$(comment_queue "$root_only" | jq '.[0].already_replied')"

outdated_comment='[{
  "id": 3, "path": "src/bar.ts", "line": null, "original_line": 20,
  "position": null, "in_reply_to_id": null,
  "user": {"login": "carol"}, "body": "outdated note", "diff_hunk": "@@ ..."
}]'

assert_eq "outdated true when position is null" \
  "true" \
  "$(comment_queue "$outdated_comment" | jq '.[0].outdated')"

assert_eq "outdated false when position is set" \
  "false" \
  "$(comment_queue "$root_only" | jq '.[0].outdated')"

assert_eq "line falls back to original_line when line is null" \
  "20" \
  "$(comment_queue "$outdated_comment" | jq '.[0].line')"

# ---------- actionable_reviews tests ----------

reviews='[
  {"id": 10, "state": "CHANGES_REQUESTED", "body": "Please fix the auth logic.", "user": {"login": "alice"}},
  {"id": 11, "state": "COMMENTED",         "body": "Minor nit on naming.",        "user": {"login": "bob"}},
  {"id": 12, "state": "APPROVED",          "body": "Looks good!",                 "user": {"login": "carol"}},
  {"id": 13, "state": "COMMENTED",         "body": "",                            "user": {"login": "dave"}},
  {"id": 14, "state": "COMMENTED",         "body": "## Pull request overview\nThis PR adds auth.", "user": {"login": "copilot"}}
]'

assert_eq "CHANGES_REQUESTED with body included" \
  "1" \
  "$(actionable_reviews "$reviews" | jq '[.[] | select(.id == 10)] | length')"

assert_eq "COMMENTED with body included" \
  "1" \
  "$(actionable_reviews "$reviews" | jq '[.[] | select(.id == 11)] | length')"

assert_eq "APPROVED excluded" \
  "0" \
  "$(actionable_reviews "$reviews" | jq '[.[] | select(.id == 12)] | length')"

assert_eq "COMMENTED with empty body excluded" \
  "0" \
  "$(actionable_reviews "$reviews" | jq '[.[] | select(.id == 13)] | length')"

assert_eq "PR overview boilerplate excluded" \
  "0" \
  "$(actionable_reviews "$reviews" | jq '[.[] | select(.id == 14)] | length')"

assert_eq "total actionable reviews is 2" \
  "2" \
  "$(actionable_reviews "$reviews" | jq 'length')"

echo ""
echo "$PASS passed, $FAIL failed"
exit $FAIL
