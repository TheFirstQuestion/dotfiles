#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

usage() {
  echo "Usage: parse-logs.sh <cloudwatch-insights.json>"
  exit 1
}

[[ $# -lt 1 ]] && usage
FILE="$1"
[[ ! -f "$FILE" ]] && { echo "Error: file not found: $FILE"; exit 1; }

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
cp "$FILE" "$TMP"

TOTAL=$(jq 'length' "$TMP")

# Classify all entries in one jq pass using 0x1F as field separator.
# Output per line: IS_APP(1/0) US TIMESTAMP US FULL_JSON
# IS_APP=1: has log_processed AND container name starts with backend/worker (case-insensitive)
CLASSIFY_JQ='
  .[] |
  select(type == "object") |
  select((."@message" | type) == "object") |
  . as $e |
  (."@message".log_processed // null) as $lp |
  (."@message".kubernetes.container_name // "" | ascii_downcase) as $cn |
  (
    if ($lp != null) and ($cn | test("^(backend|worker)"))
    then "1"
    else "0"
    end
  ) as $is_app |
  [$is_app, $e."@timestamp", ($e | tojson)] |
  join($sep)
'

APP_COUNT=0
INFRA_COUNT=0

# First pass: count app vs infra
while IFS=$'\x1f' read -r is_app ts entry_json; do
  if [[ "$is_app" == "1" ]]; then
    (( APP_COUNT++ )) || true
  else
    (( INFRA_COUNT++ )) || true
  fi
done < <(jq -r --arg sep $'\x1f' "$CLASSIFY_JQ" "$TMP")

# Get time range from first and last @timestamp (already sorted lexicographically by CloudWatch)
FIRST_TS=$(jq -r '.[0]."@timestamp"' "$TMP")
LAST_TS=$(jq -r '.[-1]."@timestamp"' "$TMP")
FIRST_ET=$(utc_to_et "$FIRST_TS")
LAST_ET=$(utc_to_et "$LAST_TS")

echo "Logs: ${FIRST_TS} UTC (${FIRST_ET} ET) → ${LAST_TS} UTC (${LAST_ET} ET)  (${TOTAL} entries, ${APP_COUNT} app / ${INFRA_COUNT} infra)"
echo ""
printf "%-15s %-15s %-5s %-16s %s\n" "UTC" "ET" "LVL" "CONTAINER" "MSG + KEY FIELDS"
printf "%s\n" "$(printf '%.0s-' {1..90})"

# Second pass: render rows, collapsing infra noise by second
PREV_INFRA_SECOND=""
INFRA_BUCKET_COUNT=0

flush_infra_bucket() {
  if [[ $INFRA_BUCKET_COUNT -gt 0 ]]; then
    format_infra_summary "$PREV_INFRA_SECOND" "$INFRA_BUCKET_COUNT"
    INFRA_BUCKET_COUNT=0
  fi
}

while IFS=$'\x1f' read -r is_app ts entry_json; do
  # Truncate to second for infra bucketing (remove millis)
  ts_second="${ts%.*}"

  if [[ "$is_app" == "1" ]]; then
    flush_infra_bucket
    PREV_INFRA_SECOND=""
    format_row "$ts" "$entry_json"
  else
    if [[ "$ts_second" != "$PREV_INFRA_SECOND" ]]; then
      flush_infra_bucket
      PREV_INFRA_SECOND="$ts_second"
    fi
    (( INFRA_BUCKET_COUNT++ )) || true
  fi
done < <(jq -r --arg sep $'\x1f' "$CLASSIFY_JQ" "$TMP")

flush_infra_bucket
