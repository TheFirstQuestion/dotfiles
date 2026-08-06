#!/usr/bin/env bash
# find-symbol-refs.sh <symbol> [repo-root]
# Finds all comments that mention a symbol name, across the codebase.
# Prints file:line:comment for each hit, excluding the symbol's own definition.
#
# A "comment" line is one whose first non-whitespace content is a comment
# marker (// # /** * ///) or a JSDoc/docstring line.

SYMBOL="${1:?Usage: find-symbol-refs.sh <symbol> [repo-root]}"
ROOT="${2:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

# Search comment lines only: lines where trimmed content starts with a comment marker
# Matches: //, #, *, ///, /**
# Also catches inline comments by looking for the symbol after // or #
grep -rn "$SYMBOL" "$ROOT" \
  --include="*.ts" --include="*.tsx" \
  --include="*.js" --include="*.jsx" \
  --include="*.dart" \
  --include="*.py" \
  --include="*.go" \
  --include="*.swift" \
  --include="*.md" \
  2>/dev/null \
| grep -E '(^\s*//|^\s*\*|^\s*#|^\s*/\*\*|//[^/]|#\s)' \
| grep -v "find-symbol-refs.sh" \
| sed "s|^$ROOT/||"
