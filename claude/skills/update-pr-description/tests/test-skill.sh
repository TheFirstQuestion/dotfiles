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
