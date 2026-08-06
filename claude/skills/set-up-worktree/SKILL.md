---
name: set-up-worktree
description: Use when checking out a branch or PR into an isolated git worktree with env files copied automatically. Also use when already inside a worktree (e.g. created by the superpowers worktree skill) to copy env files into it.
argument-hint: [branch-name | PR-URL-or-number]
---

## Goal

Create a git worktree for a branch (or a PR's head branch), then copy env files from the main worktree into it so the new worktree is immediately runnable.

If already inside an existing worktree, skip creation and go straight to copying env files.

## Step 0 — Detect if already in a worktree

Run the git context script to get GIT_DIR, GIT_COMMON, and current branch in one shot:

```bash
~/.claude/scripts/git-context.sh
```

Then check for submodule status:
```bash
git rev-parse --show-superproject-working-tree 2>/dev/null
```

If `GIT_DIR != GIT_COMMON` and not in a submodule: you are already in a linked worktree. Run the health check to see what (if anything) needs doing:

```bash
~/.claude/skills/set-up-worktree/check-worktree.sh
```

Parse the output. Each line is `<check>:(ok|missing|na)[=<detail>]`. Collect items that are `missing` and skip to **Step 5**:

**Always-run steps** (idempotent — run regardless of health check):
- Step 5b (`crg`) — always; build the graph every time so MCP tools work
- Step 5c (`dev_setup`) — if `tools/dev_setup.sh` exists
- Step 5e (`mcp_sync`) — always; run after Step 5 if `copy_files` was missing (needs the file to exist first), otherwise run immediately in parallel with the missing-item steps

**Health-check-gated steps** (only run if `missing`):

| missing item | sub-step to run |
|---|---|
| `copy_files` | Step 5 (copy env files) |
| `upstream` | Step 4c |
| `hooks` | Step 5d |
| `ios_spm` | Step 5f |

Run all applicable steps in parallel where possible. The only hard ordering constraint: if `copy_files` is missing, run Step 5 first and then kick off Step 5e (`mcp_sync`) alongside any remaining parallel steps.

Otherwise: continue to Step 1 to create a new worktree.

## Step 1 — Parse the argument and identify the branch

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

## Step 2 — Determine the repo root and existing worktrees

```
git rev-parse --show-toplevel
git worktree list --porcelain
```

- The repo root is needed to locate env files.
- The worktree list tells you if this branch is already checked out somewhere. If it is, report the path and skip to **Step 5** to copy env files into it — no duplicate worktrees needed.

## Step 3 — Determine the worktree path

Default convention: place the worktree **inside** the repo at `.claude/worktrees/<branch-name-slug>`, where the slug replaces `/` and non-alphanumeric chars with `-`.

Example: repo at `~/projects/my-app`, branch `feature/MOB-123-payments` → `~/projects/my-app/.claude/worktrees/feature-MOB-123-payments`

If the proposed path is inside `.claude/worktrees/`, proceed without asking — it follows the default convention. Only ask **"Worktree path: `<path>` — looks right? (yes / edit)"** if the path deviates from the default (e.g. the user suggested a custom location).

## Step 4 — Fetch and create the worktree

```
git fetch origin
git pull
```

Pull after fetch so the current branch is up to date before forking — the new worktree will start from the latest local state.

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

## Step 4b — Enter the worktree and allow access

Enter the worktree using the `EnterWorktree` tool (load via ToolSearch first if needed), then register both the worktree and the parent repo root as allowed directories:

```
EnterWorktree({ path: "<path>" })
```

```bash
~/.claude/scripts/add-allowed-directory.sh <path>
~/.claude/scripts/add-allowed-directory.sh <repo-root>
```

Registering the repo root ensures files in the main checkout (shared config, scripts, etc.) are accessible without permission prompts.

## Step 4c — Configure upstream tracking

Ensure the branch has an upstream so `git push` and `git pull` work without extra flags:

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

- If an upstream is already set: nothing to do.
- If no upstream but `origin/<branch>` exists (covers the "already local" case):
  ```bash
  git branch --set-upstream-to=origin/<branch> <branch>
  ```
- If the branch is brand new and has no remote counterpart yet: note that the first push must use `git push -u origin <branch>` to create the remote branch and set tracking.

## Step 5 — Copy env files

Determine the arguments for the copy script:

- **`<repo-root>`**: the main worktree — the parent directory of `git rev-parse --git-common-dir` (e.g. if that returns `/path/to/repo/.git`, the root is `/path/to/repo`).
- **`<worktree-path>`**: `pwd` when already in a worktree (Step 0 path), or the path created in Step 4.

Run the copy script (lives alongside this skill):

```
~/.claude/skills/set-up-worktree/copy-files.sh <repo-root> <worktree-path>
```

This copies `.env*`, `env-*.json`, and `.claude/settings.local.json` from the main worktree into the new one, skipping any that already exist. The script prints each file as "copied" or "skipped (already exists)".

## Step 5a — Create temp directory

Ensure the worktree has a `temp/` directory for plans and scratch files:

```bash
mkdir -p <worktree-path>/temp
```

This is idempotent — safe to run even if `temp/` already exists.

## Step 5b — Initialize code-review-graph

Always attempt to build the graph. First verify the command is available:

```bash
which code-review-graph
```

If the command is **not found**, record `CRG_STATUS=missing` and print immediately:

```
===========================================================
  WARNING: code-review-graph NOT FOUND IN PATH
  MCP graph tools will NOT work in this worktree.
  Install code-review-graph and re-run this setup step.
===========================================================
```

If the command is found, build the graph for the new worktree (this creates `.code-review-graph/graph.db` from scratch if needed):

```bash
code-review-graph build --repo <worktree-path>
```

This creates a fresh `.code-review-graph/graph.db` so MCP graph tools work immediately.

- If the build **succeeds**, record `CRG_STATUS=ok`.
- If the build **fails**, record `CRG_STATUS=failed` and print immediately:

```
===========================================================
  WARNING: CODE-REVIEW-GRAPH BUILD FAILED
  Command: code-review-graph build --repo <worktree-path>
  Error: <error output>
  MCP graph tools will NOT work in this worktree until
  this is resolved. Run the build command manually to retry.
===========================================================
```

Continue in all cases — CRG failure is not fatal to worktree setup.

## Step 5c — Run dev setup script (if present)

Check whether the worktree has a `tools/dev_setup.sh`:

```bash
[ -f "<worktree-path>/tools/dev_setup.sh" ] && echo "present" || echo "absent"
```

If **present**, run it from inside the worktree:

```bash
bash <worktree-path>/tools/dev_setup.sh
```

This handles any repo-specific setup (symlinks, generated files, local config) that must run in the new worktree context. If the command fails, report the error but continue — it is not fatal.

If **absent**, skip silently.

## Step 5d — Install git hooks (if present)

Check whether the worktree has a `tools/hooks/install.sh`:

```bash
[ -f "<worktree-path>/tools/hooks/install.sh" ] && echo "present" || echo "absent"
```

If **present**, run it from inside the worktree:

```bash
bash <worktree-path>/tools/hooks/install.sh
```

This installs any project-specific git hooks into the new worktree's `.git` directory. If the command fails, report the error but continue — it is not fatal.

If **absent**, skip silently.

## Step 5e — Sync MCP permissions

Merge user-scope MCP allow entries into the worktree's `.claude/settings.local.json` (gitignored) so subagents inherit them without prompts:

```bash
~/.claude/scripts/sync-mcp-permissions.sh <worktree-path>
```

If the command fails, report the error but continue — it is not fatal.

## Step 5f — Resolve iOS SPM dependencies (Flutter/iOS projects)

Check whether the worktree contains an iOS Xcode workspace:

```bash
find "<worktree-path>/ios" -maxdepth 1 -name "*.xcworkspace" -type d 2>/dev/null | head -1
```

If a workspace is found, resolve Swift Package Manager dependencies so Xcode build phase scripts (e.g. Crashlytics `run`) can locate their SPM checkout paths in DerivedData:

```bash
xcodebuild -resolvePackageDependencies \
  -workspace <workspace-path> \
  -scheme Runner 2>&1 | tail -5
```

- If it **succeeds**, note "iOS SPM dependencies resolved ✓" for the Step 6 summary.
- If it **fails**, note for the Step 6 summary:

```
===========================================================
  WARNING: iOS SPM DEPENDENCY RESOLUTION FAILED
  Command: xcodebuild -resolvePackageDependencies ...
  Error: <error output>
  Build phase scripts (e.g. Crashlytics) will fail until
  resolved. Run the command manually or open Xcode to
  trigger package resolution.
===========================================================
```

If no workspace is found, skip silently.

## Step 6 — Report

Print a summary:
- Worktree path (as a clickable path if the terminal supports it)
- Branch name
- `temp/` directory: "created ✓" or "already existed"
- Env files copied (list each) or "no env files found"
- Any env files skipped (already existed)
- CRG status: "graph built ✓" / "⚠ code-review-graph not found in PATH" / "⚠ graph build failed — MCP graph tools unavailable"
- iOS SPM status (if applicable): "SPM dependencies resolved ✓" / "⚠ SPM resolution failed — Xcode builds may fail"
- Reminder to run any install steps if the project has them (e.g. `npm install`, `bundle install`) — check for `package.json`, `Gemfile`, `pyproject.toml`, or `go.mod` in the new worktree and mention the appropriate install command.

Finish with:
> "Worktree ready at `<path>`. To remove it later: `git worktree remove <path>`"

## Common Mistakes

- Creating a worktree for a branch already checked out somewhere — fails or creates duplicate state
- Forgetting to run install steps after setup — worktree not immediately runnable
