---
name: set-up-worktree
description: Use when checking out a branch or PR into an isolated git worktree with env files copied automatically.
argument-hint: [branch-name | PR-URL-or-number]
---

## Goal

Create a git worktree for a branch (or a PR's head branch), then copy env files from the main worktree into it so the new worktree is immediately runnable.

## Step 0 — Parse the argument and identify the branch

The argument is free-form. Extract the target branch by scanning in order:

**PR reference** — look for:
- A GitHub PR URL: `https://github.com/<owner>/<repo>/pull/<number>`
- A bare PR number: `#123` or just `123` (only if numeric and no branch name present)

**Branch name** — any remaining token that looks like a branch name (letters, hyphens, slashes, dots).

**Resolve a PR reference to a branch name:**
```
gh pr view <number-or-url> --json headRefName,baseRefName,url -q '{branch: .headRefName, base: .baseRefName, url: .url}'
```

If neither a PR nor a branch was found in the argument, ask: **"Which branch or PR do you want to check out as a worktree?"**

## Step 1 — Determine the repo root and existing worktrees

```
git rev-parse --show-toplevel
git worktree list --porcelain
```

- The repo root is needed to locate env files.
- The worktree list tells you if this branch is already checked out somewhere. If it is, report the path and stop — no duplicate worktrees needed.

## Step 2 — Determine the worktree path

Default convention: place the worktree as a sibling of the repo root, named `<repo-name>-<branch-name-slug>`, where the slug replaces `/` and non-alphanumeric chars with `-`.

Example: repo at `~/projects/my-app`, branch `feature/MOB-123-payments` → `~/projects/my-app-feature-MOB-123-payments`

Show the proposed path and ask: **"Worktree path: `<path>` — looks right? (yes / edit)"**

- If **edit**: ask for the path they want.

## Step 3 — Fetch and create the worktree

```
git fetch origin
```

Then create the worktree. There are two cases:

**Branch exists on remote but not locally:**
```
git worktree add <path> --track -b <branch> origin/<branch>
```

**Branch already exists locally:**
```
git worktree add <path> <branch>
```

**Branch does not exist anywhere** (new branch scenario):
```
git worktree add <path> -b <branch>
```

If the command fails, report the error and stop.

## Step 3b — Configure upstream tracking

After creating the worktree, ensure the branch has an upstream so `git push` and `git pull` work without extra flags:

```
git -C <path> rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

- If an upstream is already set: nothing to do.
- If no upstream but `origin/<branch>` exists (covers the "already local" case):
  ```
  git -C <path> branch --set-upstream-to=origin/<branch> <branch>
  ```
- If the branch is brand new and has no remote counterpart yet: note that the first push must use `git push -u origin <branch>` to create the remote branch and set tracking.

## Step 4 — Copy env files

Run the copy script (lives alongside this skill):

```
~/.claude/skills/set-up-worktree/copy-files.sh <repo-root> <worktree-path>
```

This copies `.env*`, `env-*.json`, and `.claude/settings.local.json` from the main worktree into the new one, skipping any that already exist. The script prints each file as "copied" or "skipped (already exists)".

## Step 5 — Report

Print a summary:
- Worktree path (as a clickable path if the terminal supports it)
- Branch name
- Env files copied (list each) or "no env files found"
- Any env files skipped (already existed)
- Reminder to run any install steps if the project has them (e.g. `npm install`, `bundle install`) — check for `package.json`, `Gemfile`, `pyproject.toml`, or `go.mod` in the new worktree and mention the appropriate install command.

Finish with:
> "Worktree ready at `<path>`. To remove it later: `git worktree remove <path>`"

## Common Mistakes

- Creating a worktree for a branch already checked out somewhere — fails or creates duplicate state
- Forgetting to run install steps after setup — worktree not immediately runnable
