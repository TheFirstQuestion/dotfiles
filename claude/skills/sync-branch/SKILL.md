---
name: sync-branch
description: Use when syncing the current branch with a target branch or PR.
argument-hint: [branch-name | remote/branch | PR-URL-or-number]
---

## Goal

Bring changes from one branch into another, resolving straightforward conflicts automatically and presenting unclear ones for human judgment.

## Step 0 — Parse the arguments and identify from-branch and into-branch

The arguments are free-form natural language. Extract meaning by scanning for these patterns in order:

**Find a PR reference** — look for:
- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A bare PR number: `#123` or just `123` (only if numeric and no branch name is present)
- The word `"this"` or `"this one"` with no URL/number → means the current branch's open PR

**Find branch names** — after stripping PR references and filler words (`with`, `this`, `one`, `and`, `the`, `into`, `onto`, `from`), any remaining token that looks like a branch name (contains letters, hyphens, slashes, or dots) is a branch reference.

**Determine from-branch and into-branch:**
- If two branch names are present: the first is the from-branch (where changes come from), the second is the into-branch (where changes land).
- If one branch name is present alongside a PR reference: the branch is the from-branch, the PR's head branch is the into-branch.
- If only a PR reference is present: from-branch = PR's `baseRefName`, into-branch = PR's `headRefName`.
- If only one branch name and no PR: that branch is the from-branch; into-branch is the current branch.
- If nothing is present: into-branch = current branch; auto-detect from-branch (see below).

**Resolve any PR reference:**
```
gh pr view <number-or-url> --json baseRefName,headRefName,url
```

**Auto-detect from-branch when not specified:**
1. Check for a tracking remote: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null`
2. Check for an open PR on the current branch: `gh pr view --json baseRefName -q '.baseRefName' 2>/dev/null`
3. If neither, ask the user which branch to bring changes from.

**Confirm with the user** before proceeding:
> "Bring changes from `<from-branch>` into `<into-branch>`? (yes / no)"

If the into-branch isn't checked out, check it out now (stashing uncommitted changes first if needed).

Fetch the latest from the remote before proceeding:
```
git fetch origin
```

## Step 1 — Check current state

Run these in parallel:
```
git status --porcelain
git log origin/<from-branch>..HEAD --oneline
git log HEAD..origin/<from-branch> --oneline
```

Report:
- Whether there are uncommitted local changes (stash if so — note the stash for later)
- How many commits the into-branch is ahead of the from-branch
- How many commits the into-branch is behind the from-branch

If the into-branch is already up to date (0 behind), tell the user and stop.

## Step 2 — Choose strategy

Default to **rebase** if the into-branch has no open PR and has not been pushed to remote (or only pushed by this session). Default to **merge** if the branch has an open PR or is a shared branch. Only ask when genuinely ambiguous:

**"Rebase or merge? (rebase / merge)"**

- **rebase** — rewrites local commits on top of the from-branch. Cleaner history, but rewrites SHAs. Good for feature branches not yet pushed or where force-push is acceptable.
- **merge** — creates a merge commit. Preserves history. Better for shared branches or when force-push is not desirable.

## Step 3 — Execute

### If rebase:
```
git rebase origin/<from-branch>
```

If conflicts arise, for each conflicted file:
1. Read the conflict markers in the file.
2. Assess whether the resolution is unambiguous (one side is clearly correct — e.g. the incoming change adds something the into-branch doesn't touch, or vice versa).
3. **If unambiguous:** resolve automatically, stage, and continue: `git rebase --continue`
4. **If ambiguous:** show the user the conflict diff and ask how to resolve. Apply their decision, stage, and continue.

If rebase fails unrecoverably: `git rebase --abort` and report what went wrong.

### If merge:
```
git merge origin/<from-branch>
```

Apply the same conflict-resolution logic as rebase above. If merge fails unrecoverably: `git merge --abort` and report.

## Step 4 — Post-sync check

Run:
```
git log origin/<from-branch>..HEAD --oneline
git status --porcelain
```

Confirm:
- The into-branch is now ahead of the from-branch by the expected number of commits (original ahead count, same commits)
- Working tree is clean
- If a stash was created in Step 1, remind the user: `git stash pop` to restore their changes

Report a brief summary: how many commits brought in, any conflicts resolved (automatic vs. manual), and whether a push is needed (`git push` or `git push --force-with-lease` for rebase).

## Common Mistakes

- Forgetting to pop the stash after sync — local changes left stranded
- Force-pushing a shared branch after rebase — rewrites history others depend on
- Proceeding past unresolved conflicts — broken state committed to branch
