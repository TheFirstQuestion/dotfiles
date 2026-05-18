# Pre-Commit Atomic Gate Design

**Date:** 2026-05-18
**Status:** Approved

## Problem

The pre-commit gate (`pre-commit-gate.sh`) blocks `git commit` unless a hash written by the pre-commit skill matches the current working tree. This prevents committing without running the skill — but only if the skill actually runs `gate.sh write` at the end.

The failure mode: Claude runs the pre-commit skill but skips ahead to Step 5 (`gate.sh write`) without completing Steps 0–4. The gate is then satisfied without the checklist having been run. The hook cannot detect this because the hash is correct regardless of whether the steps were completed.

## Solution

Two changes to `pre-commit/SKILL.md` only. No changes to `gate.sh`, the hook, or `settings.json`.

### A — Hard gate language

A `<HARD-GATE>` block at the top of the skill, modeled on the pattern used in `brainstorming/SKILL.md`:

> DO NOT run `gate.sh write` or proceed to Step 5 until all tasks for Steps 0–4 are marked `completed`. This is not optional and cannot be skipped.

This gives Claude a strong explicit instruction that overrides any tendency to skip ahead.

### B — Task-enforced checklist

At the start of the skill, before Step 0, Claude creates one task per step via `TaskCreate`. Each step section includes:
- Opening: "Mark this task `in_progress` before starting."
- Closing: "Mark this task `completed` before proceeding to the next step."

Step 5 additionally requires: "Confirm all previous tasks are `completed` before running `gate.sh write`."

This makes skipping require two active violations (ignoring the hard gate AND not creating/completing tasks) rather than one passive omission (forgetting to run the skill properly).

## What does NOT change

- `gate.sh` — write/remove interface unchanged
- `pre-commit-gate.sh` — hash comparison logic unchanged
- `settings.json` — hook wiring unchanged
- Checklist content — what each step does is unchanged; only the scaffolding wrapping each step changes

## Files changed

- `claude/skills/pre-commit/SKILL.md` — add hard gate block + task scaffolding
