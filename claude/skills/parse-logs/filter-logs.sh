#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

usage() {
  cat <<USAGE
Usage: filter-logs.sh <file.json> [flags]

Flags:
  --errors          Level >= 50 only
  --warn            Level >= 40 only
  --app-only        Suppress infra noise entirely
  --grep <pattern>  Case-insensitive match in msg/reqUrl/err.message/raw log
  --req <reqId>     Exact reqId match
  --trace <id>      Exact trace_id match
  --patient <id>    Partial patient UUID match anywhere in entry
  --from <HH:MM:SS> Include entries at or after this UTC time
  --to <HH:MM:SS>   Include entries at or before this UTC time
USAGE
  exit 1
}

[[ $# -lt 1 ]] && usage
FILE="$1"; shift
[[ ! -f "$FILE" ]] && { echo "Error: file not found: $FILE"; exit 1; }

OPT_ERRORS=false
OPT_WARN=false
OPT_APP_ONLY=false
OPT_GREP=""
OPT_REQ=""
OPT_TRACE=""
OPT_PATIENT=""
OPT_FROM=""
OPT_TO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --errors)   OPT_ERRORS=true ;;
    --warn)     OPT_WARN=true ;;
    --app-only) OPT_APP_ONLY=true ;;
    --grep)     OPT_GREP="$2"; shift ;;
    --req)      OPT_REQ="$2"; shift ;;
    --trace)    OPT_TRACE="$2"; shift ;;
    --patient)  OPT_PATIENT="$2"; shift ;;
    --from)     OPT_FROM="$2"; shift ;;
    --to)       OPT_TO="$2"; shift ;;
    *) echo "Unknown flag: $1"; usage ;;
  esac
  shift
done

TMP=$(mktemp)
ENTRIES_TMP=$(mktemp)
trap 'rm -f "$TMP" "$ENTRIES_TMP"' EXIT
cp "$FILE" "$TMP"

TOTAL=$(jq 'length' "$TMP")

# Extract fields from each entry in one jq pass.
# Uses ASCII 0x1F (Unit Separator) as the record-field separator so that empty
# fields (e.g. a missing reqId) are preserved. Tab and SOH (0x01) cannot be
# used reliably: bash `read` collapses consecutive whitespace IFS chars for tab,
# and 0x01 is silently ignored as an IFS separator in some bash/locale configs.
# 0x1F is guaranteed non-whitespace and non-printable, safe in tojson() output
# because tojson() encodes control characters as JSON \uXXXX escape sequences.
#
# Output fields per line:
#   TIMESTAMP US CN US LVL US HAS_LP US REQ US TRC US SRCH US JSON
#   (HAS_LP = "1" if log_processed exists, "0" otherwise; used for --app-only check)
EXTRACT_JQ='
  .[] |
  select(type == "object") |
  select((."@message" | type) == "object") |
  . as $e |
  (."@message".log_processed // null) as $lp |
  (."@message".kubernetes.container_name // "") as $cn |
  (if $lp != null then "1" else "0" end) as $has_lp |
  (if $lp then $lp.level else (."@message".level // 0) end) as $lvl |
  (if $lp then ($lp.reqId // "") else (."@message".reqId // "") end) as $req |
  (if $lp then ($lp.trace_id // "") else (."@message".trace_id // "") end) as $trc |
  [
    (if $lp then ($lp.msg // "") else (."@message".msg // "") end),
    (if $lp then ($lp.reqUrl // "") else "" end),
    (if $lp then (($lp.err // {}).message // "") else "" end),
    (."@message".log // ""),
    (."@message".msg // "")
  ] | join(" ") as $srch |
  [$e."@timestamp", $cn, ($lvl | tostring), $has_lp, $req, $trc, $srch, ($e | tojson)] |
  join($sep)
'

while IFS=$'\x1f' read -r ts cn lvl has_lp req_id trace_id searchable entry_json; do
  # app-only: must have log_processed AND container is backend or worker (case-insensitive).
  # Uses pre-extracted fields to avoid spawning a child jq process per entry.
  if $OPT_APP_ONLY; then
    [[ "$has_lp" == "1" ]] || continue
    cn_lower=$(echo "$cn" | tr '[:upper:]' '[:lower:]')
    case "$cn_lower" in
      backend*|worker*) ;;
      *) continue ;;
    esac
  fi

  # level filter: convert to integer first (non-numeric string levels become 0)
  # so (( )) arithmetic is safe and won't trigger set -e on invalid comparison
  if $OPT_ERRORS || $OPT_WARN; then
    lvl_num=$( [[ "$lvl" =~ ^[0-9]+$ ]] && echo "$lvl" || echo "0" )
    if $OPT_ERRORS && (( lvl_num < 50 )); then continue; fi
    if $OPT_WARN   && (( lvl_num < 40 )); then continue; fi
  fi

  # reqId exact match
  if [[ -n "$OPT_REQ" && "$req_id" != "$OPT_REQ" ]]; then continue; fi

  # trace_id exact match
  if [[ -n "$OPT_TRACE" && "$trace_id" != "$OPT_TRACE" ]]; then continue; fi

  # patient UUID: partial match in the raw JSON
  if [[ -n "$OPT_PATIENT" ]]; then
    echo "$entry_json" | grep -qi "$OPT_PATIENT" || continue
  fi

  # grep: match against pre-extracted searchable text
  if [[ -n "$OPT_GREP" ]]; then
    echo "$searchable" | grep -qi "$OPT_GREP" || continue
  fi

  # time window (UTC HH:MM:SS lexicographic comparison)
  if [[ -n "$OPT_FROM" || -n "$OPT_TO" ]]; then
    ts_hms="${ts##* }"     # strip date
    ts_hms="${ts_hms%%.*}" # strip millis
    if [[ -n "$OPT_FROM" && "$ts_hms" < "$OPT_FROM" ]]; then continue; fi
    if [[ -n "$OPT_TO"   && "$ts_hms" > "$OPT_TO"   ]]; then continue; fi
  fi

  echo "${ts}|||${entry_json}" >> "$ENTRIES_TMP"
done < <(jq -r --arg sep $'\x1f' "$EXTRACT_JQ" "$TMP")

MATCHED=$(wc -l < "$ENTRIES_TMP" | tr -d ' ')

if (( MATCHED > 0 )); then
  FIRST_TS=$(head -1 "$ENTRIES_TMP" | cut -d'|' -f1)
  LAST_TS=$(tail  -1 "$ENTRIES_TMP" | cut -d'|' -f1)
  FIRST_ET=$(utc_to_et "$FIRST_TS")
  LAST_ET=$(utc_to_et "$LAST_TS")
  echo "Matched ${MATCHED}/${TOTAL} entries  |  ${FIRST_TS} UTC (${FIRST_ET} ET) → ${LAST_TS} UTC (${LAST_ET} ET)"
else
  echo "Matched 0/${TOTAL} entries — no results"
fi

echo ""
printf "%-15s %-15s %-5s %-16s %s\n" "UTC" "ET" "LVL" "CONTAINER" "MSG + KEY FIELDS"
printf "%s\n" "$(printf '%.0s-' {1..90})"

if (( MATCHED > 0 )); then
  while IFS= read -r row; do
    ts="${row%%|||*}"
    entry="${row#*|||}"
    format_row "$ts" "$entry"
  done < "$ENTRIES_TMP"
fi
