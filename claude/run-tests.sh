#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
total_pass=0; total_fail=0
shopt -s nullglob

for test_file in "$SCRIPT_DIR"/skills/*/tests/test-skill.sh; do
  skill=$(basename "$(dirname "$(dirname "$test_file")")")
  echo "=== $skill ==="
  status=0
  output=$(bash "$test_file") || status=$?
  echo "$output"
  pass=$(echo "$output" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo 0)
  fail=$(echo "$output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo 0)
  total_pass=$((total_pass + pass))
  total_fail=$((total_fail + fail))
done

echo ""
echo "=== Total: $total_pass passed, $total_fail failed ==="
exit $((total_fail > 0 ? 1 : 0))
