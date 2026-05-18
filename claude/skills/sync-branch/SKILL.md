---
name: sync-branch
description: Use when syncing the current branch with a target branch or PR.
argument-hint: [branch-name | remote/branch | PR-URL-or-number]
---

## Goal

Bring the current branch up to date with a target branch (or a PR's base branch), resolving straightforward conflicts automatically and presenting unclear ones for human judgment.

## Step 0 — Parse the arguments and identify source + target

The arguments are free-form natural language. Extract meaning by scanning for these patterns in order:

**Find a PR reference** — look for:
- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A bare PR number: `#123` or just `123` (only if numeric and no branch name is present)
- The word `"this"` or `"this one"` with no URL/number → means the current branch's open PR

**Find branch names** — after stripping PR references and filler words (`with`, `this`, `one`, `and`, `the`, `against`, `into`, `onto`, `from`), any remaining token that looks like a branch name (contains letters, hyphens, slashes, or dots) is a branch reference.

**Determine source and target:**
- If two branch names are present: the first is the source (branch to sync), the second is the target (branch to sync against).
- If one branch name is present alongside a PR reference: the branch is the target, the PR's head branch is the source.
- If only a PR reference is present: source = PR's `headRefName`, target = PR's `baseRefName`.
- If only one branch name and no PR: that branch is the target; source is the current branch.
- If nothing is present: source = current branch; auto-detect target (see below).

**Resolve any PR reference:**
```
gh pr view <number-or-url> --json baseRefName,headRefName,url
```

**Auto-detect target when not specified:**
1. Check for a tracking remote: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`
2. Check for an open PR on the current branch: `gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null`
3. If neither, ask the user which branch to sync against.

**Confirm with the user** before proceeding:
> "Syncing `<source>` against `<target>`. Is that right?"

If the source branch isn't checked out, check it out now (stashing uncommitted changes first if needed).

Fetch the latest from the remote before proceeding:
```
git fetch origin
```

## Step 1 — Check current state

Run these in parallel:
```
git status --porcelain
git log origin/<target>..HEAD --oneline
git log HEAD..origin/<target> --oneline
```

Report:
- Whether there are uncommitted local changes (stash if so — note the stash for later)
- How many commits the current branch is ahead of target
- How many commits the current branch is behind target

If the branch is already up to date (0 behind), tell the user and stop.

## Step 2 — Choose strategy

Ask: **"Rebase or merge? (rebase / merge)"**

- **rebase** — rewrites local commits on top of the target. Cleaner history, but rewrites SHAs. Good for feature branches not yet pushed or where force-push is acceptable.
- **merge** — creates a merge commit. Preserves history. Better for shared branches or when force-push is not desirable.

## Step 3 — Execute

### If rebase:
```
git rebase origin/<target>
```

If conflicts arise, for each conflicted file:
1. Read the conflict markers in the file.
2. Assess whether the resolution is unambiguous (one side is clearly correct — e.g. the incoming change adds something the current branch doesn't touch, or vice versa).
3. **If unambiguous:** resolve automatically, stage, and continue: `git rebase --continue`
4. **If ambiguous:** show the user the conflict diff and ask how to resolve. Apply their decision, stage, and continue.

If rebase fails unrecoverably: `git rebase --abort` and report what went wrong.

### If merge:
```
git merge origin/<target>
```

Apply the same conflict-resolution logic as rebase above. If merge fails unrecoverably: `git merge --abort` and report.

## Step 4 — Post-sync check

Run:
```
git log origin/<target>..HEAD --oneline
git status --porcelain
```

Confirm:
- Branch is now ahead of target by the expected number of commits (original ahead count, same commits)
- Working tree is clean
- If a stash was created in Step 1, remind the user: `git stash pop` to restore their changes

Report a brief summary: how many commits synced, any conflicts resolved (automatic vs. manual), and whether a push is needed (`git push` or `git push --force-with-lease` for rebase).
