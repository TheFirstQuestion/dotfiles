#!/bin/bash
# Usage: git-commit.sh <subject> [body]
# Commits with the required "Written with Claude Code" footer baked in.
# Automatically adds a "Refs: TICKET-123" footer if a ticket reference is found in the subject.
# Use this instead of heredoc-style git commit -m to avoid obfuscation prompts.
set -euo pipefail

subject="$1"
body="${2:-}"

# Extract ticket reference (e.g. MOB-264, DOCS-00) from the subject line.
ticket=""
if [[ "$subject" =~ ([A-Z]+-[0-9]+) ]]; then
  ticket="${BASH_REMATCH[1]}"
fi

refs_footer=""
if [[ -n "$ticket" ]]; then
  refs_footer="Refs: $ticket"
fi

if [[ -n "$body" ]]; then
  body_section="$body

Written with Claude Code"
else
  body_section="Written with Claude Code"
fi

if [[ -n "$refs_footer" ]]; then
  msg="$subject

$body_section

$refs_footer"
else
  msg="$subject

$body_section"
fi

git commit -m "$msg"
