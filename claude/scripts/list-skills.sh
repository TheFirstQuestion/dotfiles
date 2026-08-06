#!/usr/bin/env bash
# Lists available skills from all sources: personal, project, and installed plugins.
# For each skill, prints its name, description, and argument-hint from SKILL.md frontmatter.

# Extract a single frontmatter field value from a SKILL.md file.
# Handles both inline values ("key: value") and YAML block scalars ("key: >\n  value...").
# Usage: get_field <file> <field-name>
get_field() {
  local file="$1"
  local field="$2"
  # Extract content between the first two "---" lines, then parse the field.
  awk -v field="$field" '
    /^---/{ fm++; next }
    fm >= 2 { exit }
    fm == 1 {
      if (capturing) {
        # Continue collecting indented lines for block scalars
        if (/^[[:space:]]/) {
          sub(/^[[:space:]]+/, "")
          val = val " " $0
          next
        } else {
          capturing = 0
        }
      }
      if (match($0, "^" field ": *(.*)$")) {
        rest = substr($0, RSTART + length(field) + 2)
        # Strip leading spaces
        gsub(/^[[:space:]]+/, "", rest)
        if (rest == ">" || rest == "|" || rest == "") {
          capturing = 1
          val = ""
        } else {
          val = rest
          capturing = 0
        }
      }
    }
    END { gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); print val }
  ' "$file"
}

# Print one skill entry from a SKILL.md file.
print_skill() {
  local file="$1"
  local prefix="${2:-}"
  local name description hint

  name=$(get_field "$file" "name")
  description=$(get_field "$file" "description")
  hint=$(get_field "$file" "argument-hint")

  [ -z "$name" ] && return

  # Strip surrounding YAML quotes if present (e.g. description: "...")
  description="${description#\"}" ; description="${description%\"}"
  description="${description#\'}" ; description="${description%\'}"

  printf "  %-40s %s\n" "${prefix}${name}" "${description}"
  [ -n "$hint" ] && printf "  %-40s args: %s\n" "" "${hint}"
}

# Print all SKILL.md files under a directory, one per skill subfolder.
print_skills_dir() {
  local dir="$1"
  local prefix="${2:-}"
  [ -d "$dir" ] || return
  for skill_md in "$dir"/*/SKILL.md; do
    [ -f "$skill_md" ] && print_skill "$skill_md" "$prefix"
  done
}

echo "=== Personal skills (~/.claude/skills/) ==="
print_skills_dir ~/.claude/skills

echo ""
echo "=== Project skills (.claude/skills/) ==="
if [ -d ".claude/skills" ]; then
  print_skills_dir .claude/skills
else
  echo "  (none)"
fi

echo ""
echo "=== Superpowers plugin skills ==="
# Use only the latest installed version to avoid duplicates across versions.
sp_latest=$(ls -d ~/.claude/plugins/cache/claude-plugins-official/superpowers/*/ 2>/dev/null \
  | sort -V | tail -1)
if [ -n "$sp_latest" ]; then
  print_skills_dir "${sp_latest}skills" "superpowers:"
fi

echo ""
echo "=== Other plugin skills ==="
find ~/.claude/plugins/cache -name "SKILL.md" 2>/dev/null \
  | grep -v "claude-plugins-official/superpowers" \
  | sort \
  | while read -r f; do print_skill "$f"; done
