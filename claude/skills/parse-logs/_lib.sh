#!/usr/bin/env bash
# Sourced by parse-logs.sh and filter-logs.sh — do not execute directly.

# utc_to_et <"YYYY-MM-DD HH:MM:SS.mmm">
# Prints the time portion in America/New_York, preserving milliseconds.
# Uses BSD date (macOS). Falls back gracefully if conversion fails.
utc_to_et() {
  local ts="$1"
  # Extract date+time without millis, and millis separately
  local ts_base="${ts%.*}"
  local millis=""
  if [[ "$ts" == *.* ]]; then
    millis=".${ts##*.}"
  fi

  # BSD date: parse as UTC, convert to epoch, then format in ET
  local epoch et_time
  epoch=$(TZ="UTC" date -j -f "%Y-%m-%d %H:%M:%S" "$ts_base" "+%s" 2>/dev/null)

  if [[ -n "$epoch" ]]; then
    et_time=$(TZ="America/New_York" date -r "$epoch" "+%H:%M:%S" 2>/dev/null)
    if [[ -n "$et_time" ]]; then
      echo "${et_time}${millis}"
    else
      echo "${ts_base##* }${millis}?"
    fi
  else
    # Fallback: just show UTC time with ? suffix
    echo "${ts_base##* }${millis}?"
  fi
}

# level_label <level_int_or_string>
# Returns a short display label: 30=INFO, 40=WARN, 50=ERROR, else the value left-padded.
level_label() {
  case "$1" in
    10) echo "TRACE" ;;
    20) echo "DEBUG" ;;
    30) echo "INFO " ;;
    40) echo "WARN " ;;
    50) echo "ERROR" ;;
    60) echo "FATAL" ;;
    DEBUG) echo "DEBUG" ;;
    INFO)  echo "INFO " ;;
    WARN)  echo "WARN " ;;
    ERROR) echo "ERROR" ;;
    *)  printf "%-5s" "$1" ;;
  esac
}

# format_row <timestamp_utc> <entry_json>
# Prints one human-readable table row.
# Uses a single jq call that outputs 0x1F-separated fields to avoid the empty-field
# collapsing that occurs when tab is used as IFS with bash `read`.
format_row() {
  local ts_utc="$1"
  local entry="$2"

  local utc_time="${ts_utc##* }"
  local et_time
  et_time=$(utc_to_et "$ts_utc")

  # Extract all display fields in one jq call using 0x1F (Unit Separator).
  # Fields: level US container US msg US reqId US status US reqUrl US elapsed US
  #         userId US userRole US worker US jobName US jobId US event US errMsg
  local raw
  raw=$(echo "$entry" | jq -r --arg sep $'\x1f' '
    (."@message".log_processed // ."@message") as $lp |
    (."@message".kubernetes.container_name // "unknown") as $cn |
    [
      ($lp.level // "" | tostring),
      $cn,
      ($lp.msg // $lp.log // ""),
      ($lp.reqId // ""),
      ($lp.status // "" | if type == "number" then tostring else (if . == null then "" else . end) end),
      ($lp.reqUrl // ""),
      ($lp.elapsedTime // "" | if type == "number" then (floor | tostring) + "ms" else "" end),
      ($lp.userId // "" | if type == "number" then tostring else (if . == null then "" else . end) end),
      ($lp.userRole // ""),
      ($lp.worker // ""),
      ($lp.jobName // ""),
      ($lp.jobId // ""),
      ($lp.event // ""),
      (($lp.err // {}).message // "")
    ] | join($sep)
  ')

  local level container msg req_id http_status req_url elapsed user_id user_role job_worker job_name job_id job_event err_msg
  IFS=$'\x1f' read -r level container msg req_id http_status req_url elapsed user_id user_role job_worker job_name job_id job_event err_msg <<< "$raw"

  local kv=""
  [[ -n "$req_id"      ]] && kv="$kv reqId=$req_id"
  [[ -n "$http_status" ]] && kv="$kv status=$http_status"
  [[ -n "$req_url"     ]] && kv="$kv url=${req_url%%\?*}"  # strip query string
  [[ -n "$elapsed"     ]] && kv="$kv elapsed=$elapsed"
  [[ -n "$user_id"     ]] && kv="$kv userId=$user_id"
  [[ -n "$user_role"   ]] && kv="$kv role=$user_role"
  [[ -n "$job_worker"  ]] && kv="$kv worker=$job_worker"
  [[ -n "$job_name"    ]] && kv="$kv jobName=$job_name"
  [[ -n "$job_id"      ]] && kv="$kv jobId=$job_id"
  [[ -n "$job_event"   ]] && kv="$kv event=$job_event"
  [[ -n "$err_msg"     ]] && kv="$kv err=\"$err_msg\""

  local lbl
  lbl=$(level_label "$level")

  printf "%-15s %-15s %-5s %-16s %s%s\n" \
    "$utc_time" "$et_time" "$lbl" "$container" "$msg" "$kv"
}

# format_infra_summary <timestamp_second> <count>
# Prints one collapsed infra noise line.
format_infra_summary() {
  local ts="$1"
  local count="$2"
  local utc_time="${ts##* }"
  local et_time
  et_time=$(utc_to_et "$ts")
  printf "%-15s %-15s [infra: %d events suppressed]\n" \
    "$utc_time" "$et_time" "$count"
}
