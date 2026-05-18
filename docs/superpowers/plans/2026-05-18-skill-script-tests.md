# Skill Script Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an offline test suite for the three skill bash scripts with a central runner and per-skill test files.

**Architecture:** Each skill gets `tests/test-skill.sh` with an inline harness (no external deps). `claude/run-tests.sh` discovers and runs all suites. Tests exercise pure logic — grep/awk/jq pipelines with inline fixture data, no `gh` invocations.

**Tech Stack:** bash, jq, grep, awk.

---

### Task 1: Create the central runner

**Files:**
- Create: `claude/run-tests.sh`

- [ ] **Step 1: Create `claude/run-tests.sh`**

Create `/Users/steven/dotfiles/claude/run-tests.sh` with this exact content:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
total_pass=0; total_fail=0

for test_file in "$SCRIPT_DIR"/skills/*/tests/test-skill.sh; do
  skill=$(basename "$(dirname "$(dirname "$test_file")")")
  echo "=== $skill ==="
  output=$(bash "$test_file"); status=$?
  echo "$output"
  pass=$(echo "$output" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)
  fail=$(echo "$output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  ((total_pass += pass)) || true
  ((total_fail += fail)) || true
done

echo ""
echo "=== Total: $total_pass passed, $total_fail failed ==="
exit $total_fail
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /Users/steven/dotfiles/claude/run-tests.sh
```

- [ ] **Step 3: Verify runner finds no test files yet (gracefully)**

```bash
cd /Users/steven/dotfiles && bash claude/run-tests.sh
```

Expected: `=== Total: 0 passed, 0 failed ===` (no test files exist yet, glob expands to nothing). Exit 0.

Note: if the glob returns the literal string `skills/*/tests/test-skill.sh` (no match), the script may print an error. If so, add `shopt -s nullglob` before the for loop in `run-tests.sh`.

- [ ] **Step 4: Commit**

```bash
cd /Users/steven/dotfiles
git add claude/run-tests.sh
git commit -m "$(cat <<'EOF'
Add run-tests.sh central test runner for skill scripts

Written with Claude Code
EOF
)"
```

---

### Task 2: Create update-pr-description tests

**Files:**
- Create: `claude/skills/update-pr-description/tests/test-skill.sh`

- [ ] **Step 1: Create the test directory**

```bash
mkdir -p /Users/steven/dotfiles/claude/skills/update-pr-description/tests
```

- [ ] **Step 2: Create `test-skill.sh`**

Create `/Users/steven/dotfiles/claude/skills/update-pr-description/tests/test-skill.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Offline tests for extract-tickets.sh and pr-data.sh logic.
# No gh invocations — tests pure pipeline and jq transform logic.

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

MONDAY_BASE="https://dimerhealth-cast.monday.com/item"

# ---------- extract-tickets.sh: pipeline logic ----------
echo "extract-tickets.sh"

pipeline() {
  printf '%s\n' "$@" \
    | grep -oE '[A-Za-z]+-[0-9]+' \
    | awk -F'-' '{printf "%s-%s\n", toupper($1), $2}' \
    | sort -u
}

assert_eq "extracts ticket from branch name" \
  "MOB-123" \
  "$(pipeline "fix/mob-123-payment-flow")"

assert_eq "uppercases lowercase prefix" \
  "MOB-123" \
  "$(pipeline "mob-123")"

assert_eq "deduplicates same ticket appearing twice" \
  "MOB-123" \
  "$(pipeline "mob-123" "mob-123")"

assert_eq "returns multiple tickets sorted" \
  "$(printf 'ENG-456\nMOB-123')" \
  "$(pipeline "mob-123" "ENG-456")"

assert_eq "no match returns empty string" \
  "" \
  "$(pipeline "fix typo in readme")"

assert_eq "already-uppercase prefix preserved" \
  "ENG-99" \
  "$(pipeline "ENG-99")"

# jq JSON assembly: tickets → [{id, url}]
json_output() {
  local tickets="$1"
  if [[ -z "$tickets" ]]; then
    echo '[]'
  else
    echo "$tickets" | jq -R -s \
      --arg base "$MONDAY_BASE" \
      'split("\n") | map(select(length > 0)) | map({id: ., url: ($base + "/" + .)})'
  fi
}

assert_json_eq "empty tickets produces []" \
  '[]' \
  "$(json_output "")"

assert_json_eq "single ticket produces correct JSON" \
  '[{"id":"MOB-123","url":"https://dimerhealth-cast.monday.com/item/MOB-123"}]' \
  "$(json_output "MOB-123")"

assert_json_eq "two tickets produce correct JSON array" \
  '[{"id":"ENG-456","url":"https://dimerhealth-cast.monday.com/item/ENG-456"},{"id":"MOB-123","url":"https://dimerhealth-cast.monday.com/item/MOB-123"}]' \
  "$(json_output "$(printf 'ENG-456\nMOB-123')")"

# ---------- pr-data.sh: jq stacked PR logic ----------
echo "pr-data.sh"

stacked_prs() {
  local pr_number="$1" head_ref="$2" base_ref="$3"
  local all_prs_json="$4"
  jq -n \
    --argjson pr "{\"number\": $pr_number, \"headRefName\": \"$head_ref\", \"baseRefName\": \"$base_ref\"}" \
    --argjson all_prs "$all_prs_json" \
    '
    ($all_prs | map(select(.number != $pr.number)) | map(
      . as $o |
      if   $o.baseRefName == $pr.headRefName then
        {number: $o.number, relationship: "child"}
      elif $o.headRefName == $pr.baseRefName then
        {number: $o.number, relationship: "parent"}
      elif (($o.body // "") | test("#" + ($pr.number | tostring) + "\\b|" + $pr.headRefName; "g"))
        or (($o.title // "") | test("#" + ($pr.number | tostring) + "\\b|" + $pr.headRefName; "g")) then
        {number: $o.number, relationship: "mentioned"}
      else
        empty
      end
    ))
    '
}

assert_json_eq "baseRefName matches headRefName → child" \
  '[{"number":43,"relationship":"child"}]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":43,"url":"u","title":"t","headRefName":"feat/bar","baseRefName":"feat/foo","body":""}]')"

assert_json_eq "headRefName matches baseRefName → parent" \
  '[{"number":41,"relationship":"parent"}]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":41,"url":"u","title":"t","headRefName":"main","baseRefName":"main","body":""}]')"

assert_json_eq "body mentions #number → mentioned" \
  '[{"number":44,"relationship":"mentioned"}]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":44,"url":"u","title":"t","headRefName":"feat/other","baseRefName":"main","body":"depends on #42"}]')"

assert_json_eq "title mentions branch name → mentioned" \
  '[{"number":44,"relationship":"mentioned"}]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":44,"url":"u","title":"based on feat/foo","headRefName":"feat/other","baseRefName":"main","body":""}]')"

assert_json_eq "child takes priority over mentioned when both match" \
  '[{"number":43,"relationship":"child"}]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":43,"url":"u","title":"t","headRefName":"feat/bar","baseRefName":"feat/foo","body":"also mentions #42"}]')"

assert_json_eq "this PR excluded from stacked results" \
  '[]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":42,"url":"u","title":"t","headRefName":"feat/foo","baseRefName":"main","body":""}]')"

assert_json_eq "unrelated PR produces empty array" \
  '[]' \
  "$(stacked_prs 42 "feat/foo" "main" \
    '[{"number":99,"url":"u","title":"t","headRefName":"feat/unrelated","baseRefName":"main","body":"nothing here"}]')"

# commits extraction
commits_result=$(jq -n \
  --argjson commits '[{"messageHeadline":"Fix bug","messageBody":""},{"messageHeadline":"Add feature","messageBody":""}]' \
  '$commits | map(.messageHeadline)')
assert_json_eq "commits extracted as flat array of headlines" \
  '["Fix bug","Add feature"]' \
  "$commits_result"

# author extraction
author_result=$(jq -n \
  --argjson pr_raw '{"author":{"login":"stevengopferman","name":"Steven"}}' \
  '$pr_raw.author.login')
assert_eq "author is string login not object" \
  '"stevengopferman"' \
  "$author_result"

echo ""
echo "$PASS passed, $FAIL failed"
exit $FAIL
```

- [ ] **Step 3: Make executable**

```bash
chmod +x /Users/steven/dotfiles/claude/skills/update-pr-description/tests/test-skill.sh
```

- [ ] **Step 4: Run and verify all pass**

```bash
bash /Users/steven/dotfiles/claude/skills/update-pr-description/tests/test-skill.sh
```

Expected: all tests marked `✓`, final line `N passed, 0 failed`. Exit 0.

- [ ] **Step 5: Commit**

```bash
cd /Users/steven/dotfiles
git add claude/skills/update-pr-description/tests/test-skill.sh
git commit -m "$(cat <<'EOF'
Add offline tests for extract-tickets.sh and pr-data.sh

Written with Claude Code
EOF
)"
```

---

### Task 3: Create handle-pr-comments tests

**Files:**
- Create: `claude/skills/handle-pr-comments/tests/test-skill.sh`

- [ ] **Step 1: Create the test directory**

```bash
mkdir -p /Users/steven/dotfiles/claude/skills/handle-pr-comments/tests
```

- [ ] **Step 2: Create `test-skill.sh`**

Create `/Users/steven/dotfiles/claude/skills/handle-pr-comments/tests/test-skill.sh` with this exact content:

```bash
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
```

- [ ] **Step 3: Make executable**

```bash
chmod +x /Users/steven/dotfiles/claude/skills/handle-pr-comments/tests/test-skill.sh
```

- [ ] **Step 4: Run and verify all pass**

```bash
bash /Users/steven/dotfiles/claude/skills/handle-pr-comments/tests/test-skill.sh
```

Expected: all tests marked `✓`, final line `N passed, 0 failed`. Exit 0.

- [ ] **Step 5: Commit**

```bash
cd /Users/steven/dotfiles
git add claude/skills/handle-pr-comments/tests/test-skill.sh
git commit -m "$(cat <<'EOF'
Add offline tests for pr-comments.sh

Written with Claude Code
EOF
)"
```

---

### Task 4: Verify runner aggregates all suites

- [ ] **Step 1: Run the central runner**

```bash
cd /Users/steven/dotfiles && bash claude/run-tests.sh
```

Expected output format:
```
=== handle-pr-comments ===
pr-comments.sh
  ✓ root comment appears in queue
  ...
N passed, 0 failed

=== update-pr-description ===
extract-tickets.sh
  ✓ extracts ticket from branch name
  ...
pr-data.sh
  ✓ baseRefName matches headRefName → child
  ...
N passed, 0 failed

=== Total: N passed, 0 failed ===
```

Exit code must be 0.

- [ ] **Step 2: Commit spec and plan**

```bash
cd /Users/steven/dotfiles
git add docs/superpowers/specs/2026-05-18-skill-script-tests-design.html \
        docs/superpowers/plans/2026-05-18-skill-script-tests.md
git commit -m "$(cat <<'EOF'
Add skill script tests spec and plan

Written with Claude Code
EOF
)"
```
