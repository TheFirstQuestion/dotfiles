---
name: pr-comments-plan
description: Use when triaging unresolved PR review threads — builds a comprehensive implementation plan saved to ./temp for execution in a fresh session.
---

## Address PR Comments

Interactively triage and address unresolved review threads on a GitHub pull request.

### Step 1 — Verify prerequisites

Run this exact command and stop with a clear error if it fails:

```bash
gh --version
```

If `gh` is not installed or the command fails, output:

> **Error:** GitHub CLI (`gh`) is not installed or not on PATH. Install it from https://cli.github.com and run `gh auth login` before using this command.

Then stop. Do not proceed.

### Step 2 — Resolve the PR number

The argument passed to this command is: `$ARGUMENTS`

- If `$ARGUMENTS` contains a number (e.g. `#42` or `42`), use that as the PR number.
- Otherwise, detect the current branch with:

  ```bash
  git rev-parse --abbrev-ref HEAD
  ```

  Then find the open PR for that branch:

  ```bash
  gh pr list --head <current-branch> --state open --json number,title,url --limit 1
  ```

  If no PR is found, output:

  > **Error:** No open PR found for branch `<branch-name>`. Pass the PR number explicitly: `/pr-comments-plan 123`

  Then stop.

### Step 3 — Fetch unresolved review threads

First show the PR title and URL:

```bash
gh pr view <PR> --json number,title,url,headRefName
```

Then run the helper script to fetch and nest all comments:

```bash
node ~/.claude/skills/pr-comments-plan/get_pr_comments.ts <PR>
```

The script outputs a JSON array of root comments. Each object has this shape:

```jsonc
{
  "id": 123,
  "author": "alice",
  "author_type": "Human", // "Human", "Bot", or "Unknown" (deleted account)
  "path": "src/foo.ts", // "(general)" for issue-level and review-level comments
  "line": 42, // null for issue-level and most review-level comments
  "body": "...",
  "created_at": "2026-01-01T00:00:00Z",
  "replies": [
    { "id": 456, "author": "bob", "author_type": "Human", "body": "...", "created_at": "..." },
  ],
  "synthetic": false, // true for comments derived from a PR review body rather than a real GitHub comment thread
  "source_review_id": 5383009117, // only present when synthetic — the review this was extracted from
}
```

Comments come from three sources: unresolved inline review threads, issue-level (general) PR comments, and PR **reviews** — the top-level comment a reviewer leaves when submitting a review (approve/comment/request changes). The third source also includes individual findings embedded only as prose inside a review body (e.g. a bot's "previously missed" item that was never posted as its own inline comment) — the script splits those out as separate `synthetic: true` entries so they don't get buried inside one giant blob. Treat `synthetic` comments the same as any other comment for selection and planning purposes, but see Step 5.5 for how to handle their **Comment ID** and reply draft, since they have no real reply endpoint of their own.

Parse the JSON. If the array is empty, output:

> No review comments or unresolved threads found on PR #`<PR>`. Nothing to address.

Then stop.

### Step 4 — Prompt for comment selection

Print a numbered list of all unresolved comments, up to 10 per page:

Append `(bot)` after the author's handle when `author_type` is `"Bot"`; leave human authors unmarked. Append `(review)` after the author's handle when `synthetic` is `true` — these are review-level comments or findings embedded in a review body, not standalone inline/issue comments.

```
Unresolved comments (page 1 of 2):

  [1]  @alice  src/modules/patient/patient.service.ts:42
       The error here should use ServerError instead of throwing a raw Error.

  [2]  @bob  (general)
       Please add a migration for the new column before this merges.

  ...

  [9]  @coderabbitai[bot] (bot)  src/modules/billing/billing.service.ts:88
       Consider caching this lookup to avoid the repeated query.

  [10] @alice  src/modules/auth/auth.controller.ts:18
       This violates the logger-usage rule — remove the duplicate logger call.

  [11] @copilot-pull-request-reviewer[bot] (bot) (review)  epics/MOBI-562-session-lifecycle/epic.md:16
       Define polling latency and trigger overshoot bounds — embedded in review #5383009117, no corresponding inline comment exists.
```

Then use `AskUserQuestion` to ask which to address:

```javascript
AskUserQuestion({
  questions: [
    {
      question: 'Which comments would you like to address? (page N of M)',
      header: 'Selection',
      multiSelect: false,
      options: [
        { label: 'All on this page', description: 'Select all comments listed above.' },
        { label: 'None on this page', description: 'Skip all comments on this page.' },
        { label: 'Other', description: 'Type the numbers you want, e.g. 1,3,5' },
        // If more pages remain, add:
        // { label: 'None on this page (more pages follow)', description: '...' }
      ],
    },
  ],
});
```

- **All on this page** — add all comments on this page to the selection; if more pages remain, print the next page and ask again.
- **None on this page** — skip this page; if more pages remain, print the next page and ask again.
- **Other** — the user types comma-separated numbers (e.g. `1,3,5`); parse them, add to selection, then continue to next page if any remain.

After all pages are shown, if nothing was selected across all pages output:

> No comments selected. Exiting.

Then stop.

### Step 5 — Build the implementation plan (no code changes)

**Do not enter plan mode for this step.** Plan mode forces confirmation prompts on every MCP tool call (e.g. `code-review-graph`) even when already allow-listed, which adds unnecessary friction to what is a read-only analysis pass. Stay in the current permission mode instead.

This step is still strictly read-only: use `Read`, `AskUserQuestion`, and the `code-review-graph` MCP tools freely, but do not use `Edit`, `Write`, `NotebookEdit`, or any `Bash` command that modifies a file or the repo state — with exactly one exception: the plan document itself, written via `Write` in Step 5.5. If you find yourself about to modify a source file, stop; implementation belongs in the `/pr-comments-address` session, not here.

#### 5.1 — Gather structural context with the knowledge graph

For each selected comment, use code-review-graph MCP tools to collect context _before_ reading files directly. **Always use these tools for codebase navigation — never grep or find.** Run these in parallel where independent:

- `mcp__code-review-graph__get_review_context_tool` — full architectural context for the affected file
- `mcp__code-review-graph__semantic_search_nodes_tool` — find the relevant function/class by name or keyword from the comment body
- `mcp__code-review-graph__get_impact_radius_tool` — understand what else is affected if this code changes
- `mcp__code-review-graph__query_graph_tool` with `pattern: "callers_of"` — find all callers of the function being changed
- `mcp__code-review-graph__query_graph_tool` with `pattern: "tests_for"` — check whether the affected code has tests

Fall back to `Read` with a specific line range only for exact line content the graph cannot provide (e.g. SQL queries, schema literals). Never use `Grep` or `Bash(grep/find)` for codebase exploration.

#### 5.2 — Read the affected files and evaluate each comment

Read each file referenced by a selected comment once. Use the graph-resolved locations from 5.1; do not rely solely on the line numbers from the comment (they may have drifted). Note the current surrounding context for each change site.

For each comment, apply the `receiving-code-review` evaluation before writing the proposed change:
- Verify the suggestion is technically correct for this codebase
- YAGNI-check: grep for actual usage if the suggestion adds or removes a feature
- Check whether the suggestion conflicts with the developer's prior architectural decisions
- If the suggestion seems wrong or unclear, note it in **Convention notes** and flag it for the developer rather than planning a blind implementation
- Push back is valid — if the reviewer is wrong, the plan should say so with technical reasoning
- If `author_type` is `"Bot"` (e.g. CodeRabbit, a CI review bot), apply extra scrutiny before accepting the suggestion — automated reviewers produce more low-value nitpicks and outright-incorrect suggestions than human reviewers

Also assess whether the review thread itself is a signal that an inline comment is warranted (per `comment-keeper` Rule 3). Flag it if:
- The discussion explains a non-obvious WHY (a business rule, a constraint, a workaround) that isn't visible in the code
- There was back-and-forth or pushback that resolved into a decision — the resolution reasoning belongs near the code
- The reviewer had to ask for clarification because the code's intent was unclear

If flagged, draft the inline comment text in the **Inline comment to add** field of the plan section.

#### 5.3 — Cross-reference project conventions

Check whether each comment touches a known convention:

- `CLAUDE.md` — architecture rules, naming, config patterns
- `.claude/rules/` — all rule files
- TypeBox schema patterns, `BaseController`/`BaseService`/`BaseRepository` contracts, `ServerError` usage

Flag any comment where the reviewer's suggestion would itself violate a project convention — note the conflict in the plan.

#### 5.4 — Check whether the PR description needs updating

Fetch the current PR description:

```bash
gh pr view <PR> --json title,body
```

Compare the description against the changes being planned for each selected comment. Ask: does the existing description accurately reflect what the PR does after these changes land?

- **If yes** — note "PR description is current" in the plan and move on.
- **If no** — add a note in the plan (see § 5.5) recommending `/update-pr-description` be run before merging, with a one-sentence reason.

#### 5.5 — Compile the plan document

First, detect the worktree root:

```bash
git rev-parse --show-toplevel
```

Store the result as `<REPO_ROOT>`. Ensure the `temp/` directory exists:

```bash
mkdir -p <REPO_ROOT>/temp
```

Then write the full plan to `<REPO_ROOT>/temp/pr-<PR-number>-plan.md` using the **Write** tool (not a bash redirect). Use the following structure — one section per comment, followed by a parallelism note and a pre-commit checklist.

**File header:**

- `# PR #<number> — Implementation Plan`
- `**Branch:** <headRefName>`
- `**Generated:** <ISO date>`
- `**Comments selected:** <N>`

**Per-comment section (repeat for each comment):**

Each field must be separated by a blank line so markdown renders it as a block (not a tight list). Use this exact layout:

```markdown
## Comment [N/total]

**Comment ID:** <id>

**Reviewer:** @<author> (<author_type>)

**File:** [<path>](../<path>)

**Location:** <function or class name> — line <line>

**Comment:**

> <full comment body>

**Current code (relevant excerpt):**

```<lang>
<relevant lines>
```

**Callers affected:** <list from graph, or "none / not applicable">

**Tests covering this code:** <list from graph, or "none found">

**Convention notes:** <any rule from CLAUDE.md or .claude/rules/ that applies; flag conflicts>

**Proposed change:**

- <bullet 1>
- <bullet 2>
- …

**Inline comment to add:** <drafted comment text, or "none">

**Suggested reply draft:**

<1–2 sentences>

Written with Claude Code
```

- `**Reviewer:**` — `<author_type>` is `Human`, `Bot`, or `Unknown` (deleted account), taken verbatim from the comment JSON
- `**Location:**` — use the function name, not just the line number, so it survives rebases
- `**Inline comment to add:**` — draft only if the thread surfaced a non-obvious WHY (business rule, constraint, workaround) per `comment-keeper` Rule 3; otherwise write "none"
- `**Suggested reply draft:**` — must end with a blank line then `Written with Claude Code` on its own line
- If `synthetic` is `true`, append `(embedded in review #<source_review_id>, no standalone comment thread)` to the `**Comment ID:**` line. There is no reply endpoint for these — `pr-comments-address` posts the **Suggested reply draft** as a new general PR comment instead of an inline/issue reply; word the draft so it reads sensibly standing alone (it won't appear nested under the original review).

**Closing sections:**

- `## PR description` — either "PR description is current — no update needed" or "Run `/update-pr-description` before merging — <reason>"
- `## Parallelism recommendation` — if N >= 2, note which comments can be addressed concurrently (no overlapping files) vs. which must be sequential (same file — edits shift line numbers)
- `## Pre-commit checklist` — `pnpm lint:fix` passes, plus any convention checks identified above

#### 5.6 — Present the plan for review

Tell the developer:

> Plan written to `<REPO_ROOT>/temp/pr-<number>-plan.md`. Please review it — open the file, edit any section you disagree with, then let me know when it's ready.

Use `AskUserQuestion` to ask:

```
Question: "Is the plan ready to execute?"
Options:

- "Yes, run /pr-comments-address <REPO_ROOT>/temp/pr-<number>-plan.md in a new session"
- "I'll edit it first — check back when I say ready"
```

- If **"Yes"**: proceed to Step 7.
- If **"I'll edit it first"**: stop here. The developer will start the address session manually.

### Step 7 — Hand off to execution session

Output the following block verbatim so the developer can copy it:

```
Context is now spent on planning. Start a fresh session to keep the full context budget for implementation:

/pr-comments-address <REPO_ROOT>/temp/pr-<number>-plan.md

The plan file contains everything the address command needs: file locations, proposed changes, reply drafts, and the pre-commit checklist.
```

Then stop. Do not make any code changes.
