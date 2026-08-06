---
name: pre-commit
description: Use before committing to verify the working tree is ready — formatting, lint, tests, and conventions all pass.
---

<HARD-GATE>
DO NOT run `gate.sh write` or proceed to Step 5 until all tasks for Steps 0–4 are marked `completed`. This is not optional and cannot be skipped. If you find yourself about to write the gate hash without completed tasks for every prior step, stop and go back.
</HARD-GATE>

## Goal

Ensure the working tree is ready to commit: formatting and lint pass, tests pass, code is reviewed, project conventions are met, and nothing is broken.

## Checklist Setup — Create tasks before doing anything else

Before starting Step 0, create one task per step using `TaskCreate`:

- "Step 0 — Read conventions and discover tooling"
- "Step 1 — Review and simplify"
- "Step 2 — Run format/lint/typecheck/tests"
- "Step 3 — Convention checklist"
- "Step 4 — Pull latest and check for merge conflicts"
- "Step 5 — Stage and manual review prompt"
- "Step 6 — Final state check and gate"
- "Step 7 — Optional quiz"

Do not begin any step until its task exists.

## Step 0 — Read project conventions and discover tooling

**Mark the Step 0 task `in_progress` before starting.**

Read whichever of these exist (repo root and `.claude/`):

- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `.claude/rules`
- `.claude/conventions`

These are the primary source of truth for what commands to run. If they explicitly name lint, format, typecheck, or test commands, use those exactly.

If the convention files don't specify commands, discover them from the project itself by checking (in order of precedence):

- `package.json` → look for scripts named `lint`, `format`, `typecheck`, `test`, `check`, `validate`; also check for a `husky` key or a `.husky/` directory — read `.husky/pre-commit` to see what it runs
- `.husky/pre-commit` → read directly to see the exact commands Husky would invoke on commit
- `Makefile` → look for targets with similar names
- `pyproject.toml` / `setup.cfg` → look for `[tool.ruff]`, `[tool.black]`, `[tool.pytest]`, etc.
- `.pre-commit-config.yaml` → read the hooks list to understand what runs

Produce a checklist of commands to run, grouped as:

1. **Format** — auto-fixes code style (run first, since it may change files)
2. **Lint** — static analysis (run after format)
3. **Typecheck** — type checking if applicable
4. **Tests** — only if a test suite exists and is runnable locally

If no tooling is found for a category, skip it — do not invent commands.

**Mark the Step 0 task `completed` before proceeding.**

## Step 1 — Review and simplify (parallel)

**Mark the Step 1 task `in_progress` before starting.**

### 1a — Collect the review set

**Before building the review set, verify available skill names.** Plugin skill names vary by install. Run:

```bash
~/.claude/scripts/list-skills.sh
```

Use the actual `name:` values you find — never guess or use names from memory. Skill names change between plugin versions.

**Always-on skills — run these on every pre-commit, no exceptions (adjust names based on what you find above):**

| Role | What to look for | Purpose |
| --- | --- | --- |
| Generic code review | `code-review` skill or similar | General correctness, logic, edge cases — always runs; repo-specific review does NOT replace this |
| PR review | `requesting-code-review` (superpowers) | Always run — uses git SHAs to dispatch a focused reviewer subagent |
| Code quality / bugs | `code-simplifier` agent or similar | Correctness, reuse, simplification |
| Security | `security-compliance` skill or similar | Security vulnerabilities |
| Comments | `comment-keeper` (personal skill) | Comment accuracy and coverage |
| ts-utils (TypeScript repos only) | `use-ts-utils` skill | Run if `node_modules/dimer-ts-utils` or `node_modules/@dimer/ts-utils` exists — scan diff for utility code that should use the library instead of being reimplemented |
| Completion check | `verification-before-completion` (superpowers) | Evidence-based completion check |

Also check for **repo-specific** review skills:

```bash
ls .claude/skills/ 2>/dev/null
```

Run **every** skill listed — no filtering, no description-reading, no judgment calls. All repo-specific skills run in addition to always-on skills, not instead of them.

**Scale review depth to diff size:**

- **Small (< 25 LOC):** always-on skills + relevant repo-specific skills.
- **Medium or larger (≥ 25 LOC):** always-on skills + all repo skills, no exceptions. For very large diffs, also add extra focused passes (e.g. "focus only on edge cases and error handling") and consider splitting by logical area (data layer vs UI vs tests) so no single reviewer is overwhelmed.

Also collect and **read** all style/convention sources to pass as context to each reviewer. Read the full content of every file found — do not just pass file paths:

- `CLAUDE.md` (repo root)
- `.claude/CLAUDE.md`
- `.claude/rules/` — all rule files
- `.claude/conventions/` — all convention files
- `docs/style-guide*`, `docs/conventions*`, `docs/contributing*`
- `CONTRIBUTING.md`, `STYLE.md`, `STYLEGUIDE.md`
- Any language-specific guides (e.g. `docs/typescript.md`, `docs/dart.md`)

Read each file that exists and concatenate their contents into a single "style context" block to include in every reviewer's prompt.

### 1b — Compute the diff, then run all reviews in parallel

**Before invoking any reviewer, capture the exact diff to review:**

```bash
git diff HEAD
```

This is the uncommitted working-tree diff — the changes that will actually be in this commit. Do NOT use `git diff @{upstream}...HEAD` or `git diff main...HEAD`; those include the entire branch history and will cause reviewers to spend minutes reviewing hundreds of irrelevant files.

**Before spawning agents, tell the user which agents you are launching.** Output a brief list:

> Launching N code review agents: [skill-name-1], [skill-name-2], ...

**Spawn one Agent per reviewer.** The `Skill` tool only loads instructions into the current context — it does not spawn a worker. Send a single message with all `Agent` tool calls at once so they run concurrently. Do not call them sequentially.

Each Agent call must include in its prompt:

1. The full diff text (copy it inline — don't tell the agent to run `git diff` itself)
2. The name of the skill to follow (e.g. "Follow the comment-keeper skill")
3. Any relevant style/convention context
4. An instruction to call `mcp__code-review-graph__get_review_context_tool` on the changed files before reviewing — this provides architectural context and impact radius that improves review quality
5. An instruction to use code-review-graph tools (e.g. `mcp__code-review-graph__semantic_search_nodes_tool`, `mcp__code-review-graph__query_graph_tool`) instead of grep/find when exploring the codebase during review

Example structure per Agent call:

```
Follow the [skill-name] skill. Review this diff and report all findings.

Before reviewing, call mcp__code-review-graph__get_review_context_tool with the list of changed files from the diff to get architectural context and impact radius. Use that context to inform your review.

When you need to explore the codebase (e.g. to find callers, check how a symbol is used elsewhere, or understand dependencies), use code-review-graph tools (mcp__code-review-graph__semantic_search_nodes_tool, mcp__code-review-graph__query_graph_tool, mcp__code-review-graph__get_impact_radius_tool, etc.) instead of grep or find.

DIFF:
<paste full git diff HEAD output here>

CONVENTIONS:
<paste style context here>
```

### 1c — Consolidate and fix

After all parallel Agent calls complete, collect every finding across all reviewers. Deduplicate overlapping findings. Fix all issues before proceeding — do not move to Step 2 with open findings.

If you show the user any diff or ask them to look at changes at any point during this step, **run `git add -u` first** so they are always reviewing staged changes.

**Mark the Step 1 task `completed` before proceeding.**

## Step 2 — Run the checklist

**Mark the Step 2 task `in_progress` before starting.**

Run the discovered commands in order: format → lint → typecheck → tests.

For each:

- If it passes, note it and move on.
- If it fails, fix the issues before running the next command. Do not proceed with a failing lint or test suite.

After format runs, re-check `git diff --name-only` — if files were auto-formatted, **you must include them in the commit** (they will be picked up by `git add -u` in Step 5).

**Mark the Step 2 task `completed` before proceeding.**

## Step 3 — Convention checklist

**Mark the Step 3 task `in_progress` before starting.**

Read the changed files (`git diff --name-only HEAD`) and verify against the conventions from Step 0:

- **No unused code** — flag any unreferenced variables, imports, or functions in changed files
- **No unexplained commented-out code** — commented-out code must have an inline explanation; delete it if there's none
- **No secrets or credentials** — run `~/.claude/scripts/git-security-scan.sh` (exits 1 and prints matches if anything suspicious is found)
- **No debug artifacts** — `console.log`, `debugger`, `TODO` added in this diff (pre-existing ones are not your problem)
- **Commit target** — warn if on `main` or `master`

Fix anything that can be fixed automatically. For judgment calls, present the finding and ask before acting.

**Mark the Step 3 task `completed` before proceeding.**

## Step 4 — Pull latest and check for merge conflicts

**Mark the Step 4 task `in_progress` before starting.**

Fetch the latest from the remote and check whether the current branch has diverged:

```bash
git fetch origin
git status
```

Check for incoming changes on the base branch (usually `main` or the tracked upstream):

```bash
git log HEAD..origin/<base-branch> --oneline
```

- If there are **no incoming changes**: nothing to do, proceed.
- If there are **incoming changes**: check for conflicts using the pre-allowed script:

  ```bash
  ~/.claude/scripts/check-conflicts.sh origin/<base-branch>
  ```

  - If **no conflicts** (exit 0): note that a sync will be needed after commit but is safe to proceed.
  - If **conflicts found** (exit 1): stop and ask the user how to handle them before committing. Do not proceed with a known conflict.

**Mark the Step 4 task `completed` before proceeding.**

## Step 5 — Stage and manual review prompt

**Mark the Step 5 task `in_progress` before starting.**

**Stage all modified tracked files** so the diff the user reviews matches exactly what will be committed:

```bash
git add -u
```

If there are new untracked files that belong in this commit, ask the user whether to include them before proceeding:

> "New untracked files found: `<list>`. Stage these too? (yes / no)"

Stage any confirmed new files individually by name (not `git add .`).

Then ask the user to do a final human pass:

> "Please take a moment to read through the diff yourself and make sure the code is high quality — correct logic, no obvious issues, nothing you'd be embarrassed to have reviewed."

Wait for the user to confirm they've done this before proceeding.

If the user requests changes during this review, make them, then **re-run `git add -u`** (and stage any newly confirmed untracked files) before asking the user to review again.

**RULE: Never ask the user to review unstaged changes. `git add -u` must run before every review prompt, without exception.**

**Mark the Step 5 task `completed` after the user confirms.**

## Step 6 — Final state check and gate

**Mark the Step 6 task `in_progress` before starting.**

**IMMEDIATELY confirm all Step 0–5 tasks are `completed`. If any are not, mark Step 6 back to pending and complete the blocking task first. Do not proceed further until all Step 0–5 tasks are `completed`.**

```
git status
git diff --stat HEAD
```

Confirm:

- All intended changes are staged (including any auto-formatted files from Step 2)
- No unintended files are modified
- Lint is clean (re-run lint command to confirm if any files changed since Step 2)

**If the project uses lint-staged** (detected in Step 0 from `.husky/pre-commit` or a `lint-staged` key in `package.json`), run it now before writing the hash:

```bash
pnpm lint
git add -u
```

This ensures the gate hash is computed on the post-lint-staged tree — the exact state git will see when lint-staged runs again during `git commit`. If lint-staged has already formatted everything, it will be a no-op during the commit and the staged tree won't change.

**Write the gate hash** so the commit hook knows pre-commit has been run against this exact tree state:

```bash
~/.claude/skills/pre-commit/gate.sh write
```

The hash must be written AFTER staging (and after lint-staged if applicable), since changes to the staged tree affect it.

**Mark the Step 6 task `completed`.**

**Clear the task list** — call `TaskList` to get all task IDs, then call `TaskStop` on each one to dismiss them from the Claude Code task panel.

**DO NOT stop here. Do not say "ready to commit" or ask the user to run anything. Proceed immediately:**

1. Run `~/.claude/scripts/git-commit.sh` with a thorough subject and body that covers every file changed and why.
2. Run `git push` (or `git push -u origin <branch-name>` if no remote tracking branch exists yet).

The permission prompts on those two commands are the user's confirmation gates — they can deny either one. There is nothing else to wait for.

**After pushing, check whether a PR exists:**

```bash
gh pr view --json number 2>/dev/null
```

- If a PR exists: proceed to Step 7.
- If no PR exists: invoke the `create-pr` skill to open one, then proceed to Step 7.

## Common Mistakes

| Mistake | What goes wrong | Fix |
| --- | --- | --- |
| Writing gate hash before all tasks are `completed` | Bypasses the entire checklist | Complete all tasks first — HARD-GATE is not optional |
| Running `gate.sh write` manually without the skill | Gate satisfied with no checks run | Always run via `/pre-commit` skill |
| Asking "Commit now?" / "Push now?" via AskUserQuestion | Redundant — the `ask` permission prompt is the gate | Just run commit and push; the permission prompt lets the user say no |
| Skipping PR creation check after push | PRs never get opened | Always check `gh pr view` after push and invoke `create-pr` if none exists |
| Skipping Step 1 because "nothing to review" | Convention violations slip through | Run all reviews regardless — they're parallel so there's no cost to skipping |
| Using `Skill` tool calls for reviewers | Skills only load instructions into current context — no parallel work happens | Use `Agent` tool calls, one per reviewer, in a single message |
| Running Agent calls sequentially in Step 1 | Wall-clock time wasted | Send all Agent tool calls in one message so they run concurrently |
| Skipping Step 4 because "I just synced" | Incoming conflicts on base branch caught too late | Always fetch and check before staging |
| Staging with `git add .` instead of `git add -u` | Accidentally includes untracked secrets or build artifacts | Always use `git add -u` in Step 5; stage new files individually |
| Not re-running lint after auto-format | Format may introduce lint violations | Re-run lint if any files were auto-formatted in Step 2 |
| Writing gate hash before running lint-staged | lint-staged reformats during `git commit`, invalidating the hash | Run `pnpm lint && git add -u` in Step 6 before writing the hash |
| Completing Steps 0–5 but forgetting to run Step 6 | Gate hash never written; `git commit` blocked | Step 6 is mandatory — the skill isn't done until the gate is written |
| Presenting a diff or asking for review without staging first | User reviews unstaged changes that don't match what will be committed | Always run `git add -u` before any review prompt or diff presentation |
| Stopping after writing the gate hash with "ready to commit" | Forces the user to type an extra message — wastes their time | After the gate, immediately run `git-commit.sh` and `git push`; the permission prompts are the gate |

## Step 7 — Optional quiz

**Mark the Step 7 task `in_progress` before starting.**

Ask the user once:

> "Would you like to be quizzed on the code you just committed? (yes / no)"

- If **yes**: ask the user to run `/compact` to reduce context, then wait for them to confirm before invoking the `quiz-me` skill.
- If **no**: mark the task completed and close out.

**Mark the Step 7 task `completed`.**

## Red Flags

- "I already know it's clean"
- "I'll skip review this time, it's a trivial change"
- "The tests don't apply to this file"
- "I'll just write the gate manually"
- "All steps are done" (but Step 5 hasn't run yet)
