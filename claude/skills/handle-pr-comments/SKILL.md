---
name: handle-pr-comments
description: Work through PR review comments one at a time — fetch, plan, implement, and draft a reply for each comment with user approval at each step.
argument-hint: [pr-url-or-number]
---

## Goal

Work through every unresolved review comment on a pull request, one at a time. For each comment: show it, plan the fix, get approval, make the change, and draft a reply. Collect all replies, then commit, push, and post them at the end.

## Step 0 — Fetch all PR data

Run the `pr-comments` script (lives alongside this skill at `~/.claude/skills/handle-pr-comments/pr-comments.sh`) to fetch all data in a single call:

```
~/.claude/skills/handle-pr-comments/pr-comments.sh [<PR-number-or-URL>]
```

If an argument was provided (URL or number), pass it through. Otherwise run with no argument — the script will auto-detect the current branch's PR.

The script outputs a pre-processed JSON object with these keys:
- `pr` — PR metadata: `number`, `url`, `title`, `headRefName`, `baseRefName`, `author`, `state`
- `comment_queue` — ordered array of root inline comments, sorted by file, each with: `id`, `path`, `line`, `outdated` (bool), `already_replied` (bool), `reviewer`, `body`, `diff_hunk`, `thread_replies[]` (trimmed to `id`, `reviewer`, `body`)
- `actionable_reviews` — review-level comments worth actioning (`CHANGES_REQUESTED` or `COMMENTED`, PR overview summaries filtered out), each with: `id`, `reviewer`, `state`, `body`
- `ci` — array of CI check results (`statusCheckRollup`)
- `merge` — `{ mergeable, mergeStateStatus }`

If the script exits with a non-zero status or its output contains `{"error":...}`, report the error to the user and stop.

## Step 0b — Check out the PR branch

Use `pr.headRefName` from the script output.

If the current branch already matches, continue.

If not:
1. Check for uncommitted local changes with `git status --porcelain`. If any exist, run `git stash` before switching, and note that a stash was created so it can be popped later.
2. Run `git checkout <headRefName>`.

## Step 0c — Read project conventions

Before touching any code, read these files if they exist in the repo root:
- `CLAUDE.md`
- `.claude/rules`
- `.claude/conventions`

Use what you find to inform every edit: naming conventions, error handling patterns, lint/test commands, and any project-specific constraints.

## Step 0d — Pre-read all files in the queue

Collect the unique set of file paths from `comment_queue`. Read each file once now, before entering the comment loop. This avoids repeated file reads mid-loop and ensures line number references are based on the current file state before any edits begin.

## Step 1 — Build the comment queue

Your queue is:
1. All items in `comment_queue` where `already_replied` is `false`. Items already replied to are **silently skipped** — no loop, no display, no action needed.
2. Followed by all items in `actionable_reviews`.

**Suppressed low-confidence comments:** Copilot entries in `actionable_reviews` sometimes contain a `<details>` block titled "Comments suppressed due to low confidence". Parse each bullet point inside that block as a separate item and append them to the end of the queue (file path and line number are embedded in each bullet).

If the resulting queue is empty, tell the user (including how many were already replied to) and stop.

## Step 1b — Initialize progress tracking

Write a progress file at `/tmp/pr-comments-<repo-slug>-<pr-number>.json` with:
```json
{
  "pr_number": <number>,
  "repo": "<owner/repo>",
  "total": <queue length>,
  "completed": [],
  "pending_replies": []
}
```

The `<repo-slug>` is the repo name with `/` replaced by `-` (e.g. `Dimer-Health-dimer-cura-node`). This makes the filename unique per PR so parallel sessions on different PRs don't conflict.

Update this file after each comment is completed (add the comment ID to `completed`, add the reply to `pending_replies`).

If a progress file for this PR already exists when the skill starts, offer to resume from where it left off: show how many are done vs. remaining, then skip to the first unfinished comment.

## Step 2 — Process each comment, one at a time

For each comment in order, do the following loop:

### 2a — Present the comment

Show the user:
- Comment number out of total (e.g. `[3/9]`)
- The file and line number (or `[OUTDATED]` flag if `outdated` is true)
- The reviewer's name
- The full comment body
- Any `thread_replies` (as context, labeled clearly as existing replies)
- The relevant code snippet (use the pre-read file content from Step 0d; if outdated, note the line may have moved)

### 2b — Classify and plan

**Already-addressed check:** Assess whether the current code already satisfies the comment. This is especially important for `[OUTDATED]` comments. If already resolved, skip to 2d and draft a "this is already addressed" reply — do not ask for plan approval.

**Trivial vs. substantive:** Classify the change as one of:
- **Trivial** — a clear, mechanical fix with no ambiguity (e.g. rename a variable, add a null check, remove an unused import, fix a typo). Implement immediately without asking for plan approval — just show the diff in 2c.
- **Substantive** — architectural, ambiguous, multi-file, or anything where the right approach is not obvious. Present a plan (2–5 bullet points: what, where, why) and ask: **"Does this plan look right? (yes / no / later)"**
  - If **no**: ask what should be different, then revise.
  - If **later**: move this comment to the end of the queue and continue with the next one.
  - If **yes**: proceed.

### 2c — Make the change

Implement exactly the planned change. Use Edit (not Write) for existing files. Do not make any other changes — do not refactor, clean up, or touch unrelated code.

**Overlap awareness:** When multiple comments target the same file, edits shift line numbers. After each edit to a file, re-read the affected section before planning the next change in that file.

Show the user the resulting diff. If no code change was made, note that and proceed to 2d.

### 2d — Draft a reply comment

**Every comment gets a reply — even if no code change was made.**

Draft a short, professional reply:
- Acknowledge the comment
- Briefly describe what was changed, or explain why no change was needed (1–2 sentences)
- End with exactly: `Written with Claude Code`

Ask: **"Does this reply look right? (yes / edit)"**

- If **edit**: ask what to change, revise, and ask again.
- If **yes**: record the reply (comment ID, reply type, body) in the pending replies list. Update the progress file. Do **not** post yet.

### 2e — Next comment

Move to the next comment and repeat from 2a.

## Step 3 — Finish up

### 3a — Re-fetch to catch new comments

Re-run `~/.claude/skills/handle-pr-comments/pr-comments.sh <number>`. Compare the fresh `comment_queue` (filtering `already_replied: false` as in Step 1) against the original — any `id` not in the original list is new. If new comments exist, add them to the queue and **return to Step 2** before proceeding.

### 3b — Check CI and merge conflicts

Use the fresh script output from 3a:
- Check `ci` for any entries where `conclusion` is not `"SUCCESS"` and report them.
- Check `merge.mergeable` and `merge.mergeStateStatus` and report any conflicts.
- If either CI is failing or merge conflicts exist, ask: **"CI is failing / there are merge conflicts — fix these before committing? (yes / proceed anyway)"**
  - If **yes**: stop here and let the user resolve the issues before proceeding.
  - If **proceed anyway**: continue.

### 3c — Lint and test

Run the project's linter and test suite (use commands from `CLAUDE.md` / `.claude/rules` if found in Step 0c, otherwise infer from `package.json` or project structure). If either fails, fix the failures before proceeding. Do not commit broken code.

### 3d — Summary and pending replies

Report a summary:
- How many comments were addressed
- How many were already replied to (skipped)
- Any follow-up items the user should know about

Show the full list of pending replies (one block per reply, with the comment it targets).

### 3e — Commit and push

Commit all code changes with a message in this format:

```
Address PR #<number> review comments from <reviewer1>, <reviewer2>, ...

Written with Claude Code
```

List the unique reviewer names (including bots) whose comments were addressed. Then push.

The user has permission prompts configured for `git commit` and `git push` — attempt them directly without asking first. Only proceed to post replies after the push succeeds.

### 3f — Post replies

Post each reply using the `gh` CLI (never the GitHub MCP tools). The user has a permission prompt configured for posting comments — attempt each call directly; the full comment body will be visible in the prompt.

For inline comments, always reply to the **thread root** comment ID:

```
gh api repos/{owner}/{repo}/pulls/<number>/comments/<root-comment-id>/replies \
  -f body="<reply text>"
```

For general PR review comments (issue-style, from the reviews queue):

```
gh api repos/{owner}/{repo}/issues/<number>/comments \
  -f body="<reply text>"
```

### 3g — Clean up progress file

Once all replies are posted successfully, delete the progress file:

```
rm /tmp/pr-comments-<repo-slug>-<pr-number>.json
```
