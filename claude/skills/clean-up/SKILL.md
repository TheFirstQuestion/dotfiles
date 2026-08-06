---
name: clean-up
description: Use when cleaning up stale local branches and git worktrees after PRs have merged or been closed.
---

## Goal

Identify local branches and worktrees that are safe to delete or worth reviewing, grouped by how confident we are it's safe to remove them. Present findings and ask before deleting anything.

## Step 0 — Detect mode and discover repos

First, determine whether the current directory is itself a git repo or a folder containing repos:

```bash
git rev-parse --show-toplevel 2>/dev/null
```

- **If it succeeds** — running inside a single repo. Operate on that repo only. `REPOS=("<that path>")`.
- **If it fails** — running from a parent folder. Use the discover script:
  ```bash
  ~/.claude/scripts/clean-up-discover-repos.sh .
  ```
  Collect each printed line as an entry in `REPOS`. If none found, stop and tell the user.

All subsequent steps run **per repo** in `REPOS`. Prefix every `git` command with `git -C <repo>` and every `gh` command with `--repo <owner/name>` (derived from the `---REMOTE---` section of the gather output).

## Step 1 — Gather state (per repo)

For each repo, run the gather script (plus the PR list) in parallel:

```bash
~/.claude/scripts/clean-up-gather-state.sh <repo>
gh pr list --repo <owner/name> --state all --author "@me" --limit 100 --json number,title,headRefName,state,url
```

The gather script outputs sections delimited by `---WORKTREES---`, `---BRANCHES---`, `---DATES---`, `---HEAD---`, `---REMOTE---`.

## Step 2 — Classify each local branch (per repo)

For each local branch (excluding `main`, `master`, `develop`, and the current branch):

**PR state:**
- Match to a PR via `headRefName`
- Fetch PR state: `MERGED`, `CLOSED`, `OPEN`, or no PR found

**Commits not on remote:**
```bash
git -C <repo> log origin/<branch>..<branch> --oneline 2>/dev/null
```
If the remote branch doesn't exist, all commits are local-only.

**Uncommitted changes in worktree** (if a linked worktree exists for this branch):
```bash
git -C <worktree-path> status --porcelain
```

**Last activity date:** from `git for-each-ref` output captured in Step 1.

## Step 2 — Assign each branch/worktree to a category

### ✅ Ready to delete
All of:
- PR state is `MERGED` or `CLOSED`
- No commits ahead of remote (nothing local-only)
- No uncommitted changes in the worktree

### ⚠️ Stale
All of:
- No PR found (or PR is `CLOSED`)
- Last commit older than 2 weeks
- Flag any local-only commits or uncommitted changes in the table so the user can see them before deciding

### 🕰️ Old
All of:
- PR is `OPEN`
- Last commit older than 2 weeks
- Flag any uncommitted changes in the table

### 🔒 Keep
- Open PR with recent activity (< 2 weeks)
- Current branch

## Step 3 — Present findings

When operating on multiple repos, show a heading per repo before its tables. When on a single repo, omit the repo heading.

Show each group as a table:

**✅ Ready to delete** (will all be deleted on "yes"):
| Branch | Worktree | PR | Title |
|--------|----------|----|-------|

**⚠️ Stale — no PR, no recent activity** (prompt individually):
| Branch | Worktree | Last commit | Local-only commits | Uncommitted changes |
|--------|----------|-------------|-------------------|---------------------|

**🕰️ Old — open PR, no recent activity** (prompt individually):
| Branch | Worktree | PR | Last commit |
|--------|----------|----|-------------|

**🔒 Keep — active or has uncommitted changes:**
| Branch | Worktree | PR | Reason |
|--------|----------|----|--------|

If nothing needs action, say so and stop.

## Step 4 — Confirm and delete

Handle each group separately:

**Ready to delete:** Ask once — **"Delete all N ready-to-delete branches/worktrees? (yes / pick / no)"**
- **yes** — delete all
- **pick** — ask yes/no per item
- **no** — skip group

**Stale:** Ask per item — **"Delete `<branch>` (stale, last active <date>)? (yes / no / skip all)"**

**Old:** Ask per item — **"Delete `<branch>` (open PR #N, last active <date>)? (yes / no / skip all)"**

For each item confirmed for deletion, remove in this order:
1. Remove the worktree first (if one exists):
   ```bash
   git -C <repo> worktree remove <path> -f -f
   ```
   The double `-f` is required for Claude agent worktrees which are locked with a reason string.
2. Then delete the local branch:
   ```bash
   git -C <repo> branch -d <branch>    # use -D only if -d refuses and user confirmed
   ```

Report each deletion as it completes. If any step fails, report the error and continue.

## Step 5 — Summary

Report:
- How many branches deleted
- How many worktrees removed
- How many kept and why
- Any failures

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Silently skipping branches with uncommitted changes | Flag them in Stale/Old tables so the user can decide — don't hide them |
| Deleting a branch with local-only commits | Flag in Stale — prompt individually, not bulk |
| Removing a worktree before the branch | Always remove worktree first, then branch |
| Using `-D` without confirmation | Only use `-D` if the user explicitly confirmed for a branch `git branch -d` refuses |
| Deleting `main`/`master`/`develop` | Excluded from classification — never offered for deletion |
