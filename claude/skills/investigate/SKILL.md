---
name: investigate
description: Use when investigating a bug or unexpected behavior — especially intermittent, environment-specific, or hard-to-reproduce issues. Guides structured hypothesis-driven investigation with falsification focus and an orderly evidence log.
---

## Goal

Investigate a bug by forming and falsifying hypotheses, documenting evidence carefully, replicating in a dev environment before proposing a fix.

## Before starting

The user provides the raw symptom and context. The agent creates all four temp files and populates them as the investigation progresses — do not wait for the user to create them.

Ask the user for: exact error message or behavior, who is affected, and roughly when it started. Then begin immediately.

## Output files

Create these files in `temp/` (or repo-specific equivalent) at the start:

| File | Contents |
|------|----------|
| `1_problem.md` | Known facts at the time the investigation starts — symptom, scope, timing, reporter |
| `2_findings.md` | Evidence gathered during investigation — what was checked, what was found, what was ruled out |
| `3_steps_to_replicate.md` | Exact steps to reproduce the bug in a dev environment (fill in once confirmed) |
| `4_proposed_solution.md` | Root cause + fix (fill in only after replication confirmed) |

Update these files continuously as the investigation progresses. Never move to `4_proposed_solution.md` without first completing `3_steps_to_replicate.md`.

## Phase 1 — Document the problem (1_problem.md)

Write down only what is known for certain:
- Symptom (exact error message / behavior)
- Scope (all users? one user? one environment?)
- When it started (absolute timestamp or date)
- Who reported it and how to reproduce their exact steps

**Do not include theories here.** Facts only.

## Phase 2 — Form and falsify hypotheses

Form 3–5 hypotheses before gathering any evidence. List them all in `2_findings.md` first, then order them by falsification cost (cheapest first). Stop when one hypothesis remains confirmed and all others are falsified — or when enough are ruled out to proceed with replication.

**Evidence cost order (cheapest first):** logs/metrics → DB queries → code reading → local replication → infrastructure investigation.

For each hypothesis:
1. State it clearly: *"The medication version field is stale because the form caches on load"*
2. Identify the **cheapest evidence that would disprove it** — not confirm it
3. Gather that evidence first
4. Record result in `2_findings.md`: confirmed, falsified, or inconclusive

When a hypothesis is falsified, note *why* it was ruled out. This is as valuable as a confirmation.

If a hypothesis comes back inconclusive, deprioritize it and continue with the others. Return to it only if all other hypotheses are also falsified.

## Requesting external data

When you need logs, database output, or other external data, be specific:

- **Logs**: state the service name, the log level to filter on, the exact timeframe (e.g. `2026-07-15 14:00–14:30 UTC`), and one or two key terms to grep for
- **Database**: provide the exact SQL query to run
- **Network traces / API calls**: specify the endpoint, HTTP method, and approximate timestamp

Ask for one targeted piece of data at a time. Wait for the result before asking for the next.

## Phase 3 — Replicate (3_steps_to_replicate.md)

Do not propose a fix until you can reproduce the bug in a dev environment. Replication confirms you understand the root cause.

Steps to replicate should be runnable from scratch — no "maybe try this" steps.

If replication is not possible in dev (e.g. production-only data or infra), document why in `3_steps_to_replicate.md` and ask the user explicitly: "Replication in dev is not possible because [reason]. Proceed to propose a solution anyway?" Do not proceed without a clear yes.

## Phase 4 — Propose solution (4_proposed_solution.md)

Only fill this in after `3_steps_to_replicate.md` is complete and verified.

Structure:
- **Root cause**: one sentence
- **Fix**: what changes and why
- **Verification**: steps to confirm the fix resolves the original symptom
- **Risk / side effects**: what else could this change affect?

## 2_findings.md format

```markdown
## [TIMESTAMP] [STATUS: investigating | confirmed | falsified]
### Hypothesis: <one-sentence hypothesis>
**Evidence needed to falsify:** <what would disprove this>
**Evidence gathered:** <what was actually checked>
**Result:** confirmed | falsified | inconclusive
**Notes:** <any useful detail>
```

## Common mistakes

| Mistake | Correct approach |
|---------|-----------------|
| Confirming a hypothesis before trying to falsify it | Always ask: what would prove this wrong? |
| Asking for logs without a timeframe | Always specify start/end timestamps |
| Proposing a fix before replication | Complete `3_steps_to_replicate.md` first |
| Mixing facts and theories in `1_problem.md` | `1_problem.md` = facts only; theories go in `2_findings.md` |
| Checking code before checking data | Start with the cheapest evidence (logs, DB) before reading code |
| Investigating multiple hypotheses in parallel without documenting | One at a time, with results recorded before moving on |
