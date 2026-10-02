---
name: pre-commit
description: Use before committing to verify the working tree is ready — formatting, lint, tests, and conventions all pass.
---

<HARD-GATE>
DO NOT run `gate.sh write` or proceed to Step 5 until all tasks for Steps 0–4 are marked `completed`. This is not optional and cannot be skipped. If you find yourself about to write the gate hash without completed tasks for every prior step, stop and go back.
</HARD-GATE>

## Goal

Ensure the working tree is ready to commit: the branch is conflict-free with its trunk, formatting and lint pass, tests pass, code is reviewed, project conventions are met, and nothing is broken.

## Checklist Setup — Create tasks before doing anything else

Before starting Step 0, create one task per step using `TaskCreate`:

- "Step 0 — Read conventions and discover tooling"
- "Step 1 — Pull latest and check for merge conflicts"
- "Step 2 — Run format/lint/typecheck/tests"
- "Step 3 — Convention checklist"
- "Step 4 — Review and simplify"
- "Step 5 — Stage and manual review prompt"
- "Step 6 — Final state check and gate"
- "Step 7 — Optional quiz"

Do not begin any step until its task exists.

## Step 0 — Read project conventions and discover tooling

**Mark the Step 0 task `in_progress` before starting.**

**Back up the current working tree first, before touching anything.** This is a non-destructive snapshot — it does not modify the working tree or index — so later steps (auto-format, lint `--fix`, agent-applied fixes) have a known-good state to revert to if something goes wrong:

```bash
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_HASH=$(git stash create -u "pre-commit backup $TS")
if [ -n "$BACKUP_HASH" ]; then
  git stash store -m "pre-commit backup $TS" "$BACKUP_HASH"
  echo "Backed up working tree to stash: $BACKUP_HASH"
else
  echo "Nothing to back up — working tree matches HEAD"
fi
```

Tell the user the backup hash (or that the tree was already clean). If any later step causes unwanted changes, restore with:

```bash
git checkout "$BACKUP_HASH" -- .   # overwrite working tree with the backup
# or, to fully replace tracked + untracked state:
git stash apply "$BACKUP_HASH"
```

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

## Step 1 — Pull latest and check for merge conflicts

**Mark the Step 1 task `in_progress` before starting.**

This step has no dependency on Steps 2–4 — run it now, before paying for the checklist or the multi-agent review, so a conflict is caught before that work happens instead of after.

Fetch the latest from the remote and check whether the current branch has diverged:

```bash
git fetch origin
git status
```

**Determine the trunk branch — do not assume `main`.** Resolve it dynamically:

```bash
git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null || git remote show origin | sed -n '/HEAD branch/s/.*: //p'
```

This prints the repo's actual default branch (e.g. `main`, `master`, or `dev`). Use that value as `<base-branch>` below — never hardcode `main`.

Check for incoming changes on the base branch:

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

## Step 4 — Review and simplify (parallel)

**Mark the Step 4 task `in_progress` before starting.**

### 4a — Collect the review set

**Run the classifier script instead of manually cross-referencing skill names against the tables below.** It parses the Never-ask/Sometimes-ask tables live out of this file (so they stay the single source of truth, never duplicated elsewhere), filters the session's live invokable-skills listing against them, attaches each survivor's one-line description, and groups the result by source (Repo/User-defined/Plugin) — all the tedious enumeration Step 4a used to require by hand.

1. Write the session's live "available skills" listing — the same list `Skill`/`Agent` validate names against, surfaced via system-reminder for this session — to a file, one name per line, exactly as printed (e.g. `pre-commit`, `superpowers:brainstorming`, `mattpocock-skills:code-review`). A skill absent from that listing will make the `Skill`/`Agent` call fail outright ("Only names from the listing... are valid"), so this listing — not `list-skills.sh`'s on-disk scan of every installed plugin — is the correct input; `list-skills.sh` enumerates every plugin skill on disk regardless of whether it's enabled this session, which is why it's not used directly as the input here.

   Write it to a fresh, unique path — never the same fixed filename across runs, since multiple Claude sessions can run `/pre-commit` concurrently and would otherwise clobber each other's file. Generate the path with:

   ```bash
   mktemp "${TMPDIR:-/tmp}/claude-live-skills.XXXXXX"
   ```

   Use the path `mktemp` prints (call it `LIVE_SKILLS_FILE`) for the `Write` call and for step 2 below.

2. Run:

   ```bash
   ~/.claude/skills/pre-commit/filter-candidates.sh "$LIVE_SKILLS_FILE"
   ```

3. The script's Repo/User-defined/Plugin sections **are** the candidate set — Never-ask exclusions are already applied; do not further filter by whether a skill seems relevant to this diff. The trailing "Sometimes-ask skills in the candidate set" section lists only the handful of gated skills that survived, each with its exact gate condition — run that one concrete check per flagged skill (e.g. `find node_modules/dimer-ts-utils`) and drop it from the candidate set if the check fails.

Also glance at `ls .claude/skills/ 2>/dev/null` — the script can only classify names present in the live-skills file from step 1, so if a repo skill exists but wasn't in that listing, add it to the candidate set manually.

**Never ask — explicit list, off-topic for a commit-time review regardless of diff content.** These are workflow/process/reference skills about a different kind of task entirely, not "unlikely to be relevant to this diff." Editing this table (and the Sometimes-ask table below) is the only maintenance the script needs — each cell must stay a clean, comma-separated, backtick-quoted skill list with no trailing prose, since the script parses it literally.

| Category | Skills |
| --- | --- |
| Planning/design process (not reviewing an existing diff) | `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:executing-plans`, `superpowers:subagent-driven-development`, `superpowers:dispatching-parallel-agents`, `superpowers:writing-skills`, `superpowers:using-superpowers`, `mattpocock-skills:research`, `mattpocock-skills:domain-modeling`, `mattpocock-skills:codebase-design`, `mattpocock-skills:prototype`, `mattpocock-skills:wizard` |
| During-development debugging/TDD (not post-hoc review) | `superpowers:systematic-debugging`, `superpowers:test-driven-development`, `mattpocock-skills:diagnosing-bugs`, `mattpocock-skills:tdd`, `ios-simulator-skill:ios-simulator-skill`, `chrome-devtools-mcp:*` |
| Git-workflow (handled elsewhere in this skill, or a different flow entirely) | `superpowers:using-git-worktrees`, `superpowers:finishing-a-development-branch`, `mattpocock-skills:resolving-merge-conflicts`, `set-up-worktree`, `sync-branch`, `clean-up`, `find` |
| Post-PR follow-up (not pre-commit) | `after-pr-questions`, `senior-pr-questions`, `pr-comments-address`, `pr-comments-plan`, `create-pr`, `update-pr-description` |
| Personal config / utility / reference | `update-config`, `keybindings-help`, `run`, `init`, `workflow-authoring`, `claude-api`, `loop`, `parse-logs`, `investigate` |
| Already handled elsewhere in this skill (Step 7 asks about this separately) | `quiz-me` |
| Self-referential — this is the skill currently running | `pre-commit` |
| Task-execution guide, not a diff-review skill | `es-toolkit:migrate`, `es-toolkit:guide` |
| Other | `mattpocock-skills:grilling`, `mattpocock-skills:writing-for-agents`,`fewer-permission-prompts`, `build-release` |

**Sometimes ask — gated on a concrete repo-fact check.** Ask only if the check finds the tech present; run the actual `find`/`grep` before including — never include or exclude from a guess about what the repo "probably" is.

| Skill | Source | Ask only if... |
| --- | --- | --- |
| `dimer-ts-utils:use-ts-utils` | Plugin | `node_modules/dimer-ts-utils` or `node_modules/@dimer/ts-utils` exists |
| `dataviz` | Plugin | The diff touches charting/plotting code (a charting-lib dependency or chart-rendering file) |
| `andrej-karpathy-skills:karpathy-guidelines` | Plugin | The repo contains ML/training code (e.g. a PyTorch/JAX dependency, training notebooks) |

**Always ask (the default) — every repo skill, every user-defined skill, and every plugin skill not on either table above.** This includes `security-review`, `simplify`, `mattpocock-skills:code-review`, `superpowers:requesting-code-review`, `superpowers:receiving-code-review`, `superpowers:verification-before-completion`, `comment-keeper`, and any skill installed after this table was last updated. No action needed to include these — the absence from Never-ask and Sometimes-ask is what makes them Always-ask.

**When a newly installed skill should be off-topic or tech-gated, add it to the Never-ask or Sometimes-ask table above.** Until it's added, it defaults to Always-ask — don't improvise an ad hoc exclusion mid-run.

Within the Always-ask tier and the (tech-confirmed) Sometimes-ask tier, never further filter by whether a skill seems relevant to this specific diff — present all of them and let the user decide. The script's Repo/User-defined/Plugin output sections are exactly this candidate set, already grouped by source — use that grouping directly when building the questions below.

**Ask the user about every skill in the candidate set — every time, no memory of past selections, no further per-diff relevance filtering within that set.** Use `AskUserQuestion` with `multiSelect: true` to present the full candidate set. Since a single question caps at 4 options, split the candidate set into groups of up to 4 and pass multiple questions in one `AskUserQuestion` call (it accepts 1–4 questions per call); if the candidate set exceeds 16 skills total, make additional `AskUserQuestion` calls for the remainder. **Order the groups (and the questions built from them) Repo first, then User-defined, then Plugin** — never interleave sources within a group when a cleaner split is possible. **Keep options bare — no `(Recommended)` tags, no rationale, no editorializing.** The tool's schema requires a `description` field per option; set it to the skill's own one-line description from the script's output (already written, no need to compose new text) rather than adding commentary. Do not drop any skill from the question, and do not assume a default if the user doesn't answer.

Run only the skills the user selects. If the user selects none, skip Step 4's parallel review entirely (still note this in the Step 4 completion) but do not block on it.

**Scale review depth to diff size when presenting options** — for a small diff (< 25 LOC), you may note in the question text that fewer reviewers are likely sufficient; for medium-or-larger diffs, note that running the full set is recommended. The choice is still the user's either way. For very large diffs, also suggest extra focused passes (e.g. "focus only on edge cases and error handling") or splitting by logical area (data layer vs UI vs tests) so no single reviewer is overwhelmed — mention this as an option in the question rather than deciding unilaterally.

Also collect and **read** all style/convention sources to pass as context to each reviewer. Read the full content of every file found — do not just pass file paths:

- `CLAUDE.md` (repo root)
- `.claude/CLAUDE.md`
- `.claude/rules/` — all rule files
- `.claude/conventions/` — all convention files
- `docs/style-guide*`, `docs/conventions*`, `docs/contributing*`
- `CONTRIBUTING.md`, `STYLE.md`, `STYLEGUIDE.md`
- Any language-specific guides (e.g. `docs/typescript.md`, `docs/dart.md`)

Read each file that exists and concatenate their contents into a single "style context" block to include in every reviewer's prompt.

### 4b — Compute the diff, then run all reviews in parallel

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

### 4c — Consolidate and fix

After all parallel Agent calls complete, collect every finding across all reviewers. Deduplicate overlapping findings. Fix all issues before proceeding — do not move to Step 5 with open findings.

If you show the user any diff or ask them to look at changes at any point during this step, **run `git add -u` first** so they are always reviewing staged changes.

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

Proceed to Step 7.

## Common Mistakes

| Mistake | What goes wrong | Fix |
| --- | --- | --- |
| Writing gate hash before all tasks are `completed` | Bypasses the entire checklist | Complete all tasks first — HARD-GATE is not optional |
| Skipping the stash backup because "nothing risky has happened yet" | No safety net if auto-format, lint `--fix`, or an agent-applied fix damages the working tree in a later step | Always create the `git stash create -u` backup as the very first action in Step 0, unconditionally |
| Running `gate.sh write` manually without the skill | Gate satisfied with no checks run | Always run via `/pre-commit` skill |
| Asking "Commit now?" / "Push now?" via AskUserQuestion | Redundant — the `ask` permission prompt is the gate | Just run commit and push; the permission prompt lets the user say no |
| Skipping Step 4 because "nothing to review" | Convention violations slip through | Always ask via `AskUserQuestion` regardless of diff size — let the user decide, don't decide for them |
| Deciding which reviewers to run without asking, or reusing a prior selection | Defeats the purpose of the selection step; user loses control run-to-run | Always present the full candidate set via `AskUserQuestion` fresh, every pre-commit run |
| Filtering the candidate set by "does this look relevant to this diff" | User never even sees skills they might have wanted run, decided by a guess instead of the fixed rule | Classification is by the static Never-ask/Sometimes-ask tables only, never by perceived relevance to the diff at hand — anything absent from both tables is Always-ask regardless of how the diff looks |
| Including a Sometimes-ask skill without running its detection command | Silent over-inclusion without evidence risks asking about something that can't actually apply here | Only include a Sometimes-ask skill if a concrete command confirms its tech marker exists somewhere in the repo; never guess |
| Improvising a one-off exclusion instead of updating the Never-ask table | Classification drifts between runs, defeating the point of a fixed rule | If a skill isn't on the Never-ask or Sometimes-ask table, it's Always-ask this run; update the SKILL.md table afterward if it should be reclassified — don't decide ad hoc mid-run |
| Presenting a plugin skill from `list-skills.sh` that isn't in this session's live available-skills listing | User selects it, then the `Skill`/`Agent` call fails because the name isn't valid this session | Feed `filter-candidates.sh` the live listing (not `list-skills.sh`'s raw output) as input — it's a structural invokability check, done before tech-absence filtering, not a relevance judgment |
| Writing the live-skills listing to a fixed filename (e.g. `claude-live-skills.txt`) | Concurrent `/pre-commit` runs in other sessions clobber each other's file mid-read | Generate a unique path per run with `mktemp "${TMPDIR:-/tmp}/claude-live-skills.XXXXXX"` and use that path for both the `Write` and `filter-candidates.sh` calls |
| Manually reading `list-skills.sh` output and eyeballing it against the Never-ask/Sometimes-ask tables | Slow, and error-prone across 100+ installed-but-unrelated plugin skills | Run `~/.claude/skills/pre-commit/filter-candidates.sh <live-skills-file>` — it parses both tables straight out of this file and does the filtering |
| Adding a Never-ask/Sometimes-ask table entry with trailing prose in the Skills/Skill cell (e.g. `` `quiz-me` (see Step 7) ``) | `filter-candidates.sh` parses that cell as one literal comma-separated skill list; trailing prose becomes part of the "name" and never matches, so the skill silently isn't filtered | Keep each Skills/Skill cell as bare, comma-separated, backtick-quoted names only — put any annotation in the Category column instead |
| Using `Skill` tool calls for reviewers | Skills only load instructions into current context — no parallel work happens | Use `Agent` tool calls, one per reviewer, in a single message |
| Running Agent calls sequentially in Step 4 | Wall-clock time wasted | Send all Agent tool calls in one message so they run concurrently |
| Skipping Step 1 because "I just synced" | Incoming conflicts go undetected until after the checklist and review are already paid for | Always fetch, resolve the trunk branch, and check for conflicts first — before any other step |
| Assuming the trunk branch is always `main` | Conflict check silently compares against the wrong branch and misses real incoming changes on repos whose trunk is `dev` or something else | Resolve the base branch with `git symbolic-ref refs/remotes/origin/HEAD --short` (or `git remote show origin`) instead of hardcoding `main` |
| Staging with `git add .` instead of `git add -u` | Accidentally includes untracked secrets or build artifacts | Always use `git add -u` in Step 5; stage new files individually |
| Not re-running lint after auto-format | Format may introduce lint violations | Re-run lint if any files were auto-formatted in Step 2 |
| Writing gate hash before running lint-staged | lint-staged reformats during `git commit`, invalidating the hash | Run `pnpm lint && git add -u` in Step 6 before writing the hash |
| Completing Steps 0–5 but forgetting to run Step 6 | Gate hash never written; `git commit` blocked | Step 6 is mandatory — the skill isn't done until the gate is written |
| Presenting a diff or asking for review without staging first | User reviews unstaged changes that don't match what will be committed | Always run `git add -u` before any review prompt or diff presentation |
| Stopping after writing the gate hash with "ready to commit" | Forces the user to type an extra message — wastes their time | After the gate, immediately run `git-commit.sh` and `git push`; the permission prompts are the gate |

## Step 7 — Optional quiz

**Mark the Step 7 task `in_progress` before starting.**

Tell the user once:

> "Run `/compact` and then `/quiz-me` if you'd like to be quizzed on the code you just committed."

Do not ask yes/no, and do not invoke `quiz-me` yourself — the user runs `/compact` and `/quiz-me` on their own.

**Mark the Step 7 task `completed`.**

## Red Flags

- "I already know it's clean"
- "I'll skip review this time, it's a trivial change"
- "The tests don't apply to this file"
- "I'll just write the gate manually"
- "All steps are done" (but Step 5 hasn't run yet)
