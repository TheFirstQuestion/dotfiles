---
name: create-pr
description: Use when ready to open a new pull request for the current branch.
argument-hint: [title or description hint]
---

## Goal

Open a new PR for the current branch with a complete, accurate description — following the repo's PR template, linking all relevant tickets and stacked PRs, and reflecting what the diff actually does.

This skill delegates description writing to `update-pr-description` after creating the PR. Do not duplicate its logic here.

## Step 0 — Preflight checks

```
git status --porcelain
git rev-parse --abbrev-ref HEAD
```

- If there are uncommitted changes, stop and tell the user to commit or stash them first.
- If the current branch is `main` or `master`, stop and warn — PRs should come from feature branches.
- Capture the branch name for use below.

**Merge conflict check** — after the base branch is known (default branch from Step 1), check whether the branch merges cleanly:
```
git fetch origin
git merge-tree $(git merge-base HEAD origin/<base>) HEAD origin/<base>
```
If conflicts are detected, stop and tell the user to resolve them first (suggest running `/sync-branch`).

## Step 1 — Gather context

Run in parallel:

**Remote branch check:**
```
git ls-remote --heads origin <branch-name>
```
If the branch doesn't exist on remote yet, push it:
```
git push -u origin <branch-name>
```

**Existing PR check:**
```
gh pr view --json number,url 2>/dev/null || true
```
If a PR already exists for this branch, tell the user and stop — offer to run `update-pr-description` instead.

**Repo info:**
```
gh repo view --json defaultBranchRef,nameWithOwner
```
The default branch is the PR base unless the user specified otherwise or an argument suggests a different target (e.g. "create-pr into staging").

**PR template lookup:**
```
ls .github/PULL_REQUEST_TEMPLATE* 2>/dev/null
ls .github/pull_request_template* 2>/dev/null
ls docs/pull_request_template* 2>/dev/null
```
If a template exists, read it. This is the required structure for the description.

**Commit messages for title hint:**
```
git log origin/<default-branch>..HEAD --oneline
```

## Step 2 — Determine the PR title

If an argument was passed (e.g. `create-pr "add payment flow"`), use it as the title.

Otherwise, derive a title from:
1. The branch name (strip prefixes like `feature/`, `fix/`, `MOB-123-`, convert dashes to spaces, title-case)
2. The first commit message if it's descriptive

Show the proposed title and ask: **"PR title: `<title>` — looks right? (yes / edit)"**

- If **edit**: ask for the title they want.

## Step 3 — Determine the base branch

Default to the repo's default branch. Override if:
- The argument contains "into `<branch>`" or "against `<branch>`"  
- The current branch was created from a non-default branch (check `git merge-base` against candidates)

Show the chosen base: **"Base branch: `<base>` — correct? (yes / change)"**

## Step 4 — Write the description

Invoke the `update-pr-description` skill now, before creating the PR.

Pass it the diff, commits, branch name, title, base branch, and any PR template found in Step 1 — everything it needs to produce a complete description without a PR number yet.

`update-pr-description` will:
- Fill in the PR template (or construct a default structure)
- Link all ticket IDs found in branch name, title, and commits
- Detect and link stacked PRs
- Confirm with you before proceeding

Wait for the user to approve the description before continuing.

## Step 5 — Create the PR

Create the PR with the approved description:

```
gh pr create \
  --title "<title>" \
  --base "<base>" \
  --body "<approved description>"
```

Capture the PR number and URL from the output and report them.

## Common Mistakes

- Running on `main` or `master` — PRs must come from feature branches
- Having uncommitted changes — commit or stash first
- A PR already exists for this branch — run `update-pr-description` instead
- Wrong base branch chosen — verify before creating, can't easily change after
