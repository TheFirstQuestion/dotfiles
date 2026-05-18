#!/usr/bin/env bash
# Usage: gate.sh write | remove
# write  — compute and store the pre-commit gate hash for the current repo
# remove — delete the gate hash file for the current repo

set -euo pipefail

REPO_SLUG=$(git rev-parse --show-toplevel | xargs basename | tr '/' '-')
GATE_FILE="/tmp/pre-commit-gate-${REPO_SLUG}.hash"

case "${1:-}" in
  write)
    (git diff HEAD; git ls-files --others --exclude-standard) \
      | shasum -a 256 | cut -d' ' -f1 > "$GATE_FILE"
    echo "Gate written: $GATE_FILE"
    ;;
  remove)
    rm -f "$GATE_FILE"
    echo "Gate removed: $GATE_FILE"
    ;;
  *)
    echo "Usage: gate.sh write | remove" >&2
    exit 1
    ;;
esac
