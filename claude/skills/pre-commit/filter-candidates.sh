#!/usr/bin/env bash
# Cuts the manual work out of pre-commit Step 1a: given the session's live,
# invokable skill-name listing (one name per line, exactly as printed in the
# "available skills" system-reminder — e.g. `pre-commit`, `superpowers:brainstorming`),
# this script drops every Never-ask skill (parsed straight out of this skill's own
# SKILL.md, so the table stays the single source of truth), attaches each survivor's
# one-line description from list-skills.sh, groups by source, and flags which
# Sometimes-ask skills are still present so only those need a manual tech-check.
#
# Usage: filter-candidates.sh <live-skills-file>
#   <live-skills-file>: one skill name per line (leading "- " and surrounding
#   whitespace are stripped), copied from the session's available-skills listing.
set -euo pipefail

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: filter-candidates.sh <live-skills-file>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_MD="$SCRIPT_DIR/SKILL.md"
LIVE_FILE="$1"

# Prints one raw table row (columns joined by \t) for the table that immediately
# follows a line matching `anchor`, skipping the header and separator rows.
extract_rows() {
  local anchor="$1"
  awk -v anchor="$anchor" '
    $0 ~ anchor { in_table=1; next }
    in_table && seen_row && /^$/ { in_table=0; next }
    in_table && /^\| *---/ { next }
    in_table && /^\|/ {
      seen_row=1
      line=$0
      sub(/^\| */, "", line)
      sub(/ *\|$/, "", line)
      n = split(line, c, / *\| */)
      out = c[1]
      for (i = 2; i <= n; i++) out = out "\t" c[i]
      print out
      next
    }
  ' "$SKILL_MD"
}

# --- Never-ask: flatten the "Skills" column (col 2) across all category rows ---
never_ask_names=$(extract_rows "Never ask — explicit list" \
  | cut -f2 \
  | tail -n +2 \
  | tr ',' '\n' \
  | sed -E 's/`//g; s/^[[:space:]]+//; s/[[:space:]]+$//' \
  | grep -v '^$')

# --- Sometimes-ask: name (col 1) and gate condition (col 3) ---
sometimes_ask_rows=$(extract_rows "Sometimes ask — gated" \
  | tail -n +2 \
  | awk -F'\t' '{ gsub(/`/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1 "\t" $3 }')

# --- Live skill names, cleaned up ---
live_names=$(sed -E 's/^[[:space:]]*-[[:space:]]*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$LIVE_FILE" | grep -v '^$')

is_never_ask() {
  local candidate="$1" pattern prefix
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if [[ "$pattern" == *'*' ]]; then
      prefix="${pattern%\*}"
      [[ "$candidate" == "$prefix"* ]] && return 0
    elif [ "$candidate" = "$pattern" ]; then
      return 0
    fi
  done <<< "$never_ask_names"
  return 1
}

sometimes_ask_condition() {
  local candidate="$1" name cond
  while IFS=$'\t' read -r name cond; do
    [ -z "$name" ] && continue
    [ "$candidate" = "$name" ] && { echo "$cond"; return 0; }
  done <<< "$sometimes_ask_rows"
  return 1
}

# --- Description lookup: build a bare-name -> description map from list-skills.sh ---
skills_dump="$(~/.claude/scripts/list-skills.sh 2>/dev/null || true)"
description_for() {
  local candidate="$1" bare
  bare="${candidate##*:}"
  printf '%s\n' "$skills_dump" | awk -v exact="$candidate" -v bare="$bare" '
    $0 ~ /^  [^ ]/ {
      name=$1
      $1=""
      sub(/^[ \t]+/, "")
      desc=$0
      if (name == exact) { print desc; found=1; exit }
      if (name == bare) { fallback=desc }
    }
    END { if (!found) print fallback }
  '
}

# --- Classify survivors by source and print, plus collect Sometimes-ask flags ---
repo_out=() user_out=() plugin_out=()
sometimes_flags=()

while IFS= read -r name; do
  [ -z "$name" ] && continue
  is_never_ask "$name" && continue

  desc="$(description_for "$name")"
  line="  ${name}${desc:+ — $desc}"

  case "$name" in
    *:*) plugin_out+=("$line") ;;
    *)
      if [ -f ".claude/skills/$name/SKILL.md" ]; then
        repo_out+=("$line")
      elif [ -f "$HOME/.claude/skills/$name/SKILL.md" ]; then
        user_out+=("$line")
      else
        # Unqualified name we can't place on disk (e.g. a built-in skill) —
        # default to User-defined rather than dropping it silently.
        user_out+=("$line")
      fi
      ;;
  esac

  if cond="$(sometimes_ask_condition "$name")"; then
    sometimes_flags+=("$name — ask only if: $cond")
  fi
done <<< "$live_names"

echo "=== Repo skills (candidate set) ==="
if [ "${#repo_out[@]}" -eq 0 ]; then echo "  (none)"; else printf '%s\n' "${repo_out[@]}"; fi

echo ""
echo "=== User-defined skills (candidate set) ==="
if [ "${#user_out[@]}" -eq 0 ]; then echo "  (none)"; else printf '%s\n' "${user_out[@]}"; fi

echo ""
echo "=== Plugin skills (candidate set) ==="
if [ "${#plugin_out[@]}" -eq 0 ]; then echo "  (none)"; else printf '%s\n' "${plugin_out[@]}"; fi

echo ""
echo "=== Sometimes-ask skills in the candidate set — verify each before including ==="
if [ "${#sometimes_flags[@]}" -eq 0 ]; then
  echo "  (none)"
else
  printf '  %s\n' "${sometimes_flags[@]}"
fi
