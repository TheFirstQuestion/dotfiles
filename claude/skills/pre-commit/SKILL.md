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
- "Step 1 — Run format/lint/typecheck/tests"
- "Step 2 — Review and simplify"
- "Step 3 — Convention checklist"
- "Step 4 — Manual review prompt"
- "Step 5 — Final state check, stage, and gate"

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

## Step 1 — Run the checklist

**Mark the Step 1 task `in_progress` before starting.**

Run the discovered commands in order: format → lint → typecheck → tests.

For each:
- If it passes, note it and move on.
- If it fails, fix the issues before running the next command. Do not proceed with a failing lint or test suite.

After format runs, re-check `git diff --name-only` — if files were auto-formatted, **you must include them in the commit** (they will be picked up by `git add -u` in Step 5).

**Mark the Step 1 task `completed` before proceeding.**

## Step 2 — Review and simplify

**Mark the Step 2 task `in_progress` before starting.**

Look for a `.claude/skills/` directory in the repo root and check what skills are defined there:

```
ls .claude/skills/ 2>/dev/null
```

From the skills found, identify which are **review-oriented** — skills whose name or description suggests code review, quality checking, simplification, or analysis (e.g. `review`, `simplify`, `security-review`, `lint-check`). Run only those.

If no repo-specific review skills exist, run the generic skills in order:
1. `/review`
2. `/simplify`

Fix all issues raised before proceeding.

**Mark the Step 2 task `completed` before proceeding.**

## Step 3 — Convention checklist

**Mark the Step 3 task `in_progress` before starting.**

Read the changed files (`git diff --name-only HEAD`) and verify against the conventions from Step 0:

- **No unused code** — flag any unreferenced variables, imports, or functions in changed files
- **No unexplained commented-out code** — commented-out code must have an inline explanation; delete it if there's none
- **No secrets or credentials** — scan for API keys, tokens, passwords, or `.env` values hardcoded in changed files
- **No debug artifacts** — `console.log`, `debugger`, `TODO` added in this diff (pre-existing ones are not your problem)
- **Commit target** — warn if on `main` or `master`

Fix anything that can be fixed automatically. For judgment calls, present the finding and ask before acting.

**Mark the Step 3 task `completed` before proceeding.**

## Step 4 — Manual review prompt

**Mark the Step 4 task `in_progress` before starting.**

Before signing off, explicitly ask the user to do a final human pass:

> "Please take a moment to read through the diff yourself and make sure the code is high quality — correct logic, no obvious issues, nothing you'd be embarrassed to have reviewed."

Wait for the user to confirm they've done this before proceeding.

**Mark the Step 4 task `completed` after the user confirms.**

## Step 5 — Final state check, stage, and gate

**Mark the Step 5 task `in_progress` before starting.**

**IMMEDIATELY confirm all Step 0–4 tasks are `completed`. If any are not, mark Step 5 back to pending and complete the blocking task first. Do not proceed further until all Step 0–4 tasks are `completed`.**

```
git status
git diff --stat HEAD
```

Confirm:
- All intended changes are present (including any auto-formatted files from Step 1)
- No unintended files are modified
- Lint is clean (re-run lint command to confirm if any files changed since Step 1)

**Stage all modified tracked files** so the working tree is ready to commit:

```bash
git add -u
```

If there are new untracked files that belong in this commit, ask the user whether to include them before staging:
> "New untracked files found: `<list>`. Stage these too? (yes / no)"

Stage any confirmed new files individually by name (not `git add .`).

**Write the gate hash** so the commit hook knows pre-commit has been run against this exact tree state:

```bash
~/.claude/skills/pre-commit/gate.sh write
```

The hash must be written AFTER staging, since untracked files affect it.

**Mark the Step 5 task `completed`.**

Report a brief summary: files changed, commands run and their results, any issues fixed. End with **"Ready to commit."** — or list what still needs attention.
