# Skill Common Mistakes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Common Mistakes / Red Flags sections to all 6 custom skills, depth proportional to mistake cost.

**Architecture:** Append-only edits to 6 SKILL.md files. Deep sections (table + Red Flags) for `pre-commit` and `handle-pr-comments`; brief bullet lists for the other 4. No other files change.

**Tech Stack:** Markdown.

---

### Task 1: Add deep Common Mistakes + Red Flags to `pre-commit`

**Files:**
- Modify: `claude/skills/pre-commit/SKILL.md`

- [ ] **Step 1: Append Common Mistakes and Red Flags sections**

Append to the end of `/Users/steven/dotfiles/claude/skills/pre-commit/SKILL.md`:

```markdown

## Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| Writing gate hash before all tasks are `completed` | Bypasses the entire checklist | Complete all tasks first — HARD-GATE is not optional |
| Running `gate.sh write` manually without the skill | Gate satisfied with no checks run | Always run via `/pre-commit` skill |
| Skipping Step 2 because "nothing to review" | Convention violations slip through | Run review/simplify regardless |
| Staging with `git add .` instead of `git add -u` | Accidentally includes untracked secrets or build artifacts | Always use `git add -u`; stage new files individually |
| Not re-running lint after auto-format | Format may introduce lint violations | Re-run lint if any files were auto-formatted |
| Completing Steps 0–4 but forgetting to run Step 5 | Gate hash never written; `git commit` blocked | Step 5 is mandatory — the skill isn't done until the gate is written |

## Red Flags

- "I already know it's clean"
- "I'll skip review this time, it's a trivial change"
- "The tests don't apply to this file"
- "I'll just write the gate manually"
- "All steps are done" (but Step 5 hasn't run yet)
```

- [ ] **Step 2: Verify placement**

Confirm the two new sections appear after the last existing step (Step 5) with no content following them.

---

### Task 2: Add deep Common Mistakes + Red Flags to `handle-pr-comments`

**Files:**
- Modify: `claude/skills/handle-pr-comments/SKILL.md`

- [ ] **Step 1: Append Common Mistakes and Red Flags sections**

Append to the end of `/Users/steven/dotfiles/claude/skills/handle-pr-comments/SKILL.md`:

```markdown

## Common Mistakes

| Mistake | What goes wrong | Fix |
|---|---|---|
| Posting replies before push succeeds | Replies reference changes not on the remote yet | Always commit and push before posting |
| Making unrequested changes alongside a fix | Scope creep; reviewers didn't ask for it | Change only what the comment requests |
| Treating outdated comments as current | Code may have already moved on | Check `outdated` flag; assess current state before acting |
| Skipping Step 3c (pre-commit) before committing | Lint/format violations end up in the PR | Always run pre-commit before commit |
| Using `git add .` to stage changes | Picks up unrelated modified files | Use `git add -u` or stage by file |

## Red Flags

- "I'll reply now and push after"
- "While I'm in this file I'll also fix…"
- "The comment is outdated so I'll just skip it"
- "I'll skip pre-commit, it's just comment fixes"
```

- [ ] **Step 2: Verify placement**

Confirm the two new sections appear after Step 3h (the last existing step) with no content following them.

---

### Task 3: Add brief Common Mistakes to `create-pr`, `update-pr-description`, `sync-branch`, `set-up-worktree`

**Files:**
- Modify: `claude/skills/create-pr/SKILL.md`
- Modify: `claude/skills/update-pr-description/SKILL.md`
- Modify: `claude/skills/sync-branch/SKILL.md`
- Modify: `claude/skills/set-up-worktree/SKILL.md`

- [ ] **Step 1: Append to `create-pr/SKILL.md`**

Append to the end of `/Users/steven/dotfiles/claude/skills/create-pr/SKILL.md`:

```markdown

## Common Mistakes

- Running on `main` or `master` — PRs must come from feature branches
- Having uncommitted changes — commit or stash first
- A PR already exists for this branch — run `update-pr-description` instead
- Wrong base branch chosen — verify before creating, can't easily change after
```

- [ ] **Step 2: Append to `update-pr-description/SKILL.md`**

Append to the end of `/Users/steven/dotfiles/claude/skills/update-pr-description/SKILL.md`:

```markdown

## Common Mistakes

- Editing before reading the full diff — description will miss or misrepresent changes
- Removing existing Changelog entries — history is lost; always append, never delete
- Inventing details not present in the diff — accuracy over completeness
```

- [ ] **Step 3: Append to `sync-branch/SKILL.md`**

Append to the end of `/Users/steven/dotfiles/claude/skills/sync-branch/SKILL.md`:

```markdown

## Common Mistakes

- Forgetting to pop the stash after sync — local changes left stranded
- Force-pushing a shared branch after rebase — rewrites history others depend on
- Proceeding past unresolved conflicts — broken state committed to branch
```

- [ ] **Step 4: Append to `set-up-worktree/SKILL.md`**

Append to the end of `/Users/steven/dotfiles/claude/skills/set-up-worktree/SKILL.md`:

```markdown

## Common Mistakes

- Creating a worktree for a branch already checked out somewhere — fails or creates duplicate state
- Forgetting to run install steps after setup — worktree not immediately runnable
```

- [ ] **Step 5: Verify all 4 files**

Confirm each file ends with a `## Common Mistakes` section and the correct bullets.

---

### Task 4: Commit everything

- [ ] **Step 1: Stage all 6 skill files and the spec + plan**

```bash
git checkout -b fix/skill-common-mistakes
git add claude/skills/pre-commit/SKILL.md \
        claude/skills/handle-pr-comments/SKILL.md \
        claude/skills/create-pr/SKILL.md \
        claude/skills/update-pr-description/SKILL.md \
        claude/skills/sync-branch/SKILL.md \
        claude/skills/set-up-worktree/SKILL.md \
        docs/superpowers/specs/2026-05-18-skill-common-mistakes-design.html \
        docs/superpowers/plans/2026-05-18-skill-common-mistakes.md
```

- [ ] **Step 2: Commit**

```bash
git commit -m "Add Common Mistakes / Red Flags sections to all 6 custom skills

Written with Claude Code"
```

Expected: commit on branch `fix/skill-common-mistakes` with 8 files changed.
