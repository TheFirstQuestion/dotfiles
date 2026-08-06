---
name: find
description: Use when given a ticket slug (e.g. MOB-123, CUR-456) or PR number and asked to work on it — finds the associated branch and worktree, enters it, and ensures it is set up correctly.
argument-hint: <ticket-slug | PR-number>
---

## Goal

Given a ticket slug or PR number, locate the associated branch and worktree across all repos, enter it, and ensure it is fully set up (env files, allowed directory). Delegate the setup step to **set-up-worktree**.

## Step 1 — Parse the argument

Extract the identifier from the argument or, if no argument was given, ask: **"Which ticket or PR do you want to work on?"**

**Ticket slug** — matches pattern `[A-Z]+-\d+` (e.g. `MOB-123`, `CUR-456`, `FIX-7`). Case-insensitive on input; normalize to uppercase.

**PR number** — a bare integer, optionally prefixed with `#` (e.g. `#42` or `42`).

## Step 2 — Search for matching branches and worktrees

### 2a — Ticket slug search

Run the find script (it uses `$PWD` automatically to detect the active repo):

```bash
~/.claude/skills/find/find-branch.sh <SLUG>
```

Output is tab-separated lines, one result per match:
- `worktree  <repo-path>  <branch>  <worktree-path>  [current]` — branch is checked out as a live worktree
- `branch    <repo-path>  <branch>  (empty)          [current]` — branch exists (local or remote) but no worktree yet

The optional `current` marker means this result's repo matches the caller's working directory.

### 2b — PR lookup (if argument is a PR number)

Determine which repo the PR belongs to (try each project repo):

```bash
gh pr view <number> --repo <owner>/<repo> --json headRefName,url 2>/dev/null
```

Use the first repo that returns a result. Extract the head branch name, then run the find script with it as the slug.

## Step 3 — Resolve the match

**One match found:** Proceed to Step 4 with that branch + repo.

**Multiple matches found, one marked `current`:** Auto-select the `current` match without asking — the user is already in that repo.

**Multiple matches found, none marked `current`:** List them with repo and branch, and ask: **"Found multiple matches — which one?"**

**No match found:**
- If ticket slug: say "No branch or worktree found containing `<slug>`. Should I search for a PR with this ticket in the title?" and if yes, run:
  ```bash
  gh pr list --search "<slug>" --json number,title,headRefName,url --limit 5
  ```
- If PR number: say "No PR found with that number in any local repo. Which repo should I look in?" then retry with the specified repo.

## Step 4 — Enter the worktree or create one

**Case A: Live worktree already exists at a path**

The worktree is already checked out. Enter it using the `EnterWorktree` tool (load via ToolSearch first if needed), then register both the worktree and parent repo as allowed:

```
EnterWorktree({ path: "<worktree-path>" })
```

```bash
~/.claude/scripts/add-allowed-directory.sh <worktree-path>
~/.claude/scripts/add-allowed-directory.sh <repo-path>
```

Then invoke **set-up-worktree** to handle env file copying (it will detect the existing worktree in Step 0 and skip creation, going straight to env copy).

**Case B: Branch exists remotely but no worktree**

Invoke **set-up-worktree** with the branch name as the argument. It will create the worktree, enter it, copy env files, and report.

## Step 5 — Report

After setup completes, confirm:

- Repo: `<repo-name>`
- Branch: `<branch-name>`
- Worktree path: `<path>`
- Whether the worktree was pre-existing or freshly created

Then say: **"Ready. What would you like to do?"**

## Common Mistakes

- Searching only the current repo — the branch may be in a different project repo
- Entering the worktree directory without registering it via `add-allowed-directory.sh` — causes permission prompts for every file access
- Creating a duplicate worktree when one already exists for the branch
