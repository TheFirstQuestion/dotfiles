# extract-tickets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create `extract-tickets.sh` — a bash script that fetches PR data and extracts ticket IDs as a JSON array — and wire it into `update-pr-description` Step 2.

**Architecture:** Shell script following the `pr-comments.sh` pattern: resolve PR number/repo, fetch text sources via `gh`, extract with `grep -oE`, post-process with `awk`/`sort`/`uniq`, emit JSON via `jq`. Skill step replaced with a single script call.

**Tech Stack:** bash, gh CLI, grep, awk, sort, uniq, jq.

---

### Task 1: Write and test `extract-tickets.sh`

**Files:**
- Create: `claude/skills/update-pr-description/extract-tickets.sh`

- [ ] **Step 1: Create the script**

Create `/Users/steven/dotfiles/claude/skills/update-pr-description/extract-tickets.sh` with this exact content:

```bash
#!/usr/bin/env bash
# Extract ticket IDs from a PR and return them as a JSON array.
# Usage: extract-tickets.sh [PR-number-or-URL]
#
# Output: JSON array of {id, url} objects, e.g.:
#   [{"id":"MOB-123","url":"https://dimerhealth-cast.monday.com/item/MOB-123"}]
# Returns [] if no tickets found.
# On error: prints {"error":"..."} to stderr and exits non-zero.

set -euo pipefail

MONDAY_BASE="https://dimerhealth-cast.monday.com/item"

# ---------- resolve PR number and repo ----------
repo=""
if [[ $# -gt 0 ]]; then
  arg="$1"
  number="${arg##*/}"
  if [[ "$arg" =~ github\.com/([^/]+/[^/]+)/pull/ ]]; then
    repo="${BASH_REMATCH[1]}"
  fi
else
  number=$(gh pr view --json number -q '.number' 2>/dev/null || true)
  if [[ -z "$number" ]]; then
    echo '{"error":"No PR found. Run from a branch with an open PR, or pass a PR number."}' >&2
    exit 1
  fi
fi
if [[ -z "$repo" ]]; then
  repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner')
fi

# ---------- fetch text sources ----------
pr_json=$(gh pr view "$number" -R "$repo" \
  --json title,body,headRefName,commits)

branch=$(echo "$pr_json" | jq -r '.headRefName')
title=$(echo "$pr_json"  | jq -r '.title')
body=$(echo "$pr_json"   | jq -r '.body')
commits=$(echo "$pr_json" | jq -r '.commits[].messageHeadline')

# ---------- extract, normalize, deduplicate ----------
tickets=$(printf '%s\n%s\n%s\n%s\n' "$branch" "$title" "$body" "$commits" \
  | grep -oE '[A-Za-z]+-[0-9]+' \
  | awk -F'-' '{printf "%s-%s\n", toupper($1), $2}' \
  | sort -u)

# ---------- emit JSON ----------
if [[ -z "$tickets" ]]; then
  echo '[]'
  exit 0
fi

echo "$tickets" | jq -R -s \
  --arg base "$MONDAY_BASE" \
  'split("\n") | map(select(length > 0)) | map({id: ., url: ($base + "/" + .)})'
```

- [ ] **Step 2: Make executable**

```bash
chmod +x /Users/steven/dotfiles/claude/skills/update-pr-description/extract-tickets.sh
```

- [ ] **Step 3: Smoke test — no PR**

Run from a directory with no open PR to verify error handling:

```bash
cd /tmp && /Users/steven/dotfiles/claude/skills/update-pr-description/extract-tickets.sh
```

Expected: exits non-zero, stderr contains `{"error":"No PR found..."}`. stdout is empty.

- [ ] **Step 4: Smoke test — with a real PR**

Run from the dotfiles repo (which has open PRs on origin) or pass a known PR number:

```bash
cd /Users/steven/dotfiles && /Users/steven/dotfiles/claude/skills/update-pr-description/extract-tickets.sh 1
```

Expected: either `[]` (no tickets in that PR) or a valid JSON array. Must not error.

- [ ] **Step 5: Unit test — ticket extraction logic**

Verify the extraction and normalization inline:

```bash
echo "fix/mob-123-payment-flow" \
  | grep -oE '[A-Za-z]+-[0-9]+' \
  | awk -F'-' '{printf "%s-%s\n", toupper($1), $2}'
```

Expected output: `MOB-123`

```bash
printf 'mob-123\nENG-456\nmob-123\neng-456\n' \
  | awk -F'-' '{printf "%s-%s\n", toupper($1), $2}' \
  | sort -u
```

Expected output:
```
ENG-456
MOB-123
```

- [ ] **Step 6: Commit**

```bash
cd /Users/steven/dotfiles
git checkout -b feat/extract-tickets
git add claude/skills/update-pr-description/extract-tickets.sh
git commit -m "Add extract-tickets.sh script for update-pr-description skill

Written with Claude Code"
```

---

### Task 2: Update `update-pr-description` Step 2

**Files:**
- Modify: `claude/skills/update-pr-description/SKILL.md` (lines 52–68)

- [ ] **Step 1: Replace Step 2 content**

In `/Users/steven/dotfiles/claude/skills/update-pr-description/SKILL.md`, replace the entire `## Step 2 — Extract ticket IDs` section (lines 52–68) with:

```markdown
## Step 2 — Extract ticket IDs

Run:
```bash
~/.claude/skills/update-pr-description/extract-tickets.sh [<number-or-url>]
```

Use the JSON array output directly. Each element has `id` and `url`. If the array is empty, the Tickets section of the description gets "None".
```

- [ ] **Step 2: Verify the edit**

Confirm the old manual scanning instructions ("Scan all of the following", "prefer the existing URL") are gone and only the script call remains.

```bash
grep -n "Scan all\|prefer the existing\|monday.com" \
  /Users/steven/dotfiles/claude/skills/update-pr-description/SKILL.md
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
cd /Users/steven/dotfiles
git add claude/skills/update-pr-description/SKILL.md \
        docs/superpowers/specs/2026-05-18-extract-tickets-design.html \
        docs/superpowers/plans/2026-05-18-extract-tickets.md
git commit -m "Wire extract-tickets.sh into update-pr-description Step 2

Written with Claude Code"
```
