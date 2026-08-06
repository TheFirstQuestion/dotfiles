#!/usr/bin/env bash
# Usage: clean-up-discover-repos.sh [dir]
# Prints each immediate subdirectory of DIR (default: cwd) that is a git repo,
# one per line. Used by the clean-up skill to discover repos in a parent folder.
set -euo pipefail

dir="${1:-.}"

for d in "$dir"/*/; do
  [ -d "$d" ] || continue
  name="${d%/}"
  name="${name##*/}"
  if git -C "$d" rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "$name"
  fi
done
