---
name: clean-up
description: Use when cleaning up stale local branches, git worktrees, temp files, and obsolete git stashes after PRs have merged or been closed.
---

## Goal

Identify local branches and worktrees that are safe to delete or worth reviewing, grouped by how confident we are it's safe to remove them. Present findings and ask before deleting anything — except obviously unnecessary git stashes (see Step 1b), which are dropped automatically and reported.

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

The gather script outputs sections delimited by `---WORKTREES---`, `---BRANCHES---`, `---DATES---`, `---HEAD---`, `---STASHES---`, `---REMOTE---`.

## Step 1a — Check temp folders (per repo and per worktree)

For each repo path in `REPOS` **and** each worktree path listed in that repo's `---WORKTREES---` output, check for a `temp/` folder:

```bash
ls -A <path>/temp 2>/dev/null
```

Collect every location with non-empty output, along with its list of entries. Skip locations with no `temp/` folder or an empty one.

## Step 1b — Classify stashes (per repo)

Stashes are stored once per repo (`refs/stash`) and shared by every linked worktree, so evaluate the `---STASHES---` section once per repo — not once per worktree. Each line is `<ref>|<hash>|<unix time>|<subject>`.

**Auto-drop (no prompt)** — a stash is obviously unnecessary if either:
- Its subject starts with `pre-commit backup` **and** it is more than 24 hours old. These are safety nets created by the `pre-commit` skill; once a day has passed the run that created it has long finished. (The age guard protects a pre-commit run that is still in progress.)
- Its changes are already in the current work — `git -C <repo> diff --quiet HEAD <hash>` exits 0 (the stash tree is identical to `HEAD`).

**Drop with its branch (no separate prompt)** — a stash whose subject names a branch (`On <branch>:` / `WIP on <branch>:`) that the user confirms for deletion in Step 4. Confirming the branch/worktree deletion covers its stashes; do not ask about them again. If the user declines to delete that branch, the stash falls through to the next category.

**Prompt individually** — every other stash. Gather `git -C <repo> stash show --stat <hash>` and the age so the user can judge.

Never drop a stash that is neither auto-droppable nor explicitly confirmed.

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

**🗑️ Temp files found** (prompt per location, only shown if any location has files):
| Location | Files |
|----------|-------|

**🧳 Stashes auto-dropped** (no prompt; only shown if any):
| Stash | Created | Subject | Reason |
|-------|---------|---------|--------|

**🧳 Stashes dropped with their branch** (no separate prompt; only dropped if the branch deletion is confirmed; only shown if any):
| Stash | Created | Subject | Branch |
|-------|---------|---------|--------|

**📦 Stashes to review** (prompt individually; only shown if any):
| Stash | Created | Subject | Files changed |
|-------|---------|---------|---------------|

If nothing needs action, say so and stop.

## Step 4 — Confirm and delete

Handle each group separately:

**Ready to delete:** Ask once — **"Delete all N ready-to-delete branches/worktrees? (yes / pick / no)"**
- **yes** — delete all
- **pick** — ask yes/no per item
- **no** — skip group

**Stale:** Ask per item — **"Delete `<branch>` (stale, last active <date>)? (yes / no / skip all)"**

**Old:** Ask per item — **"Delete `<branch>` (open PR #N, last active <date>)? (yes / no / skip all)"**

**Temp files:** Ask per location — **"Delete N file(s) in `<path>/temp`? (yes / pick / no)"**
- **yes** — delete every entry in that location's `temp/`
- **pick** — list the filenames and ask yes/no per file
- **no** — skip that location

Delete confirmed temp entries with:
```bash
rm -rf <path>/temp/<entry>
```

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

**Stashes:** Run after branch/worktree deletion so you know which branches were actually deleted.
- Auto-droppable stashes (Step 1b): drop without asking.
- Stashes belonging to a branch that was just deleted: drop without asking.
- Other stashes: ask per item — **"Drop `<ref>` (`<subject>`, created <date>)? (yes / no / skip all)"**

Stash refs are positional (`stash@{N}` renumbers after each drop), so drop in descending index order, and record each stash's commit hash before dropping:
```bash
git -C <repo> stash drop 'stash@{<N>}'
```
Report the hash for every dropped stash so it can be recovered with `git stash store -m "<subject>" <hash>` (the commit stays reachable via `git fsck --unreachable` until garbage-collected).

Report each deletion as it completes. If any step fails, report the error and continue.

## Step 5 — Summary

Report:
- How many branches deleted
- How many worktrees removed
- How many temp files/folders deleted
- How many stashes dropped (auto vs. confirmed, with hashes) and how many kept
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
| Bulk-deleting temp/ without listing filenames | Always show the filenames first — a temp file may be an active plan, not stale scratch work |
| Dropping a `pre-commit backup` stash that is less than 24 hours old | A pre-commit run may still be in progress and depend on it — the age guard is mandatory |
| Dropping stashes by ascending index | `stash@{N}` renumbers after each drop, so you drop the wrong entry. Drop highest index first |
| Evaluating stashes once per worktree | Stashes are repo-wide; evaluate once per repo |
