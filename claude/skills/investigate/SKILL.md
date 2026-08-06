---
name: investigate
description: >
  USER-TRIGGERED ONLY — invoke only when the user explicitly types /investigate.
  Use when diving into production logs or data to understand why something happened
  historically — post-incident analysis, intermittent prod bugs, or behavior that
  can't be reproduced live. NOT for simple debugging, live-running code, or
  dev-environment issues.
---

## Goal

Investigate a bug by forming and falsifying hypotheses, documenting evidence carefully, replicating in a dev environment before proposing a fix.

**Write everything down.** Every hypothesis, every data point, every dead end, every exact log line — it all goes in the files. The investigation folder is a permanent record, not a scratch pad. Future investigations may reference this one; incomplete notes destroy that value. If something was said in conversation but not written in the files, it doesn't count.

**Never implement a fix during investigation.** The only code changes allowed during Phases 1–4 are temporary debug instrumentation (print statements, extra logging, diagnostic assertions). Remove all debug code before moving to Phase 5. Fixes go in a separate branch after the investigation is complete.

## Before starting

Create the investigation folder immediately. Name it `YYYY-MM-DD_short-description` (e.g. `2026-07-17_image-not-shown`) inside `temp/` (or the repo-specific equivalent). Inside it, create:

```
temp/2026-07-17_image-not-shown/
  1_problem.md             ← you will fill this in with the user
  2_findings.md            ← empty to start
  3_steps_to_replicate.md  ← empty to start
  4_proposed_solution.md   ← empty to start
  5_handoff.md             ← empty to start; filled in at the end
  logs/                    ← empty folder; user drops log exports here
```

Create all four files and the `logs/` folder before doing anything else. Then open `1_problem.md` with whatever the user has already told you.

**Clarify the problem before investigating.** Ask targeted questions to fill in any gaps — exact error text, who is affected, when it started, whether it's reproducible on demand, and any recent changes. Use the `mattpocock-skills:grilling` skill if available, or ask 3–5 focused questions. Record only confirmed facts in `1_problem.md`; do not include theories.

## Output files

| File | Contents |
| --- | --- |
| `1_problem.md` | Known facts — symptom, scope, timing, reporter, steps to trigger |
| `2_findings.md` | Evidence gathered during investigation — what was checked, what was found, what was ruled out |
| `3_steps_to_replicate.md` | Exact steps to reproduce the bug in a dev environment (fill in once confirmed) |
| `4_proposed_solution.md` | Root cause + fix (fill in only after replication confirmed) |
| `5_handoff.md` | Slack summary + full fix/remediation list (fill in at the end) |

Update these files continuously as the investigation progresses. Never move to `4_proposed_solution.md` without first completing `3_steps_to_replicate.md`.

## Phase 1 — Document the problem (1_problem.md)

Write down only what is known for certain:

- Symptom (exact error message / behavior)
- Scope (all users? one user? one environment?)
- When it started (absolute timestamp or date)
- Who reported it and how to reproduce their exact steps

**Do not include theories here.** Facts only.

End the file with a `# Problem Statements` section — numbered single-sentence definitions of the problem, one per distinct question the investigation needs to answer:

```markdown
# Problem Statements

P1. The medication form fails to save for patient X with a "snapshot conflict" error. P2. The error started occurring on 2026-07-15 and has not self-resolved.
```

Assign stable IDs (P1, P2, …) — never renumber. Add new problem statements as the investigation reveals additional distinct questions to answer.

## Phase 2 — Form and falsify hypotheses

Form 3–5 hypotheses before gathering any evidence. List them all in `2_findings.md` first, then order them by falsification cost (cheapest first). Stop when all but one hypothesis are falsified — or when enough are ruled out to proceed with replication.

**Hypothesis IDs are permanent.** Assign each hypothesis an ID (H1, H2, H3…) when it is first written. Never rename, renumber, or reassign IDs — even if H1 is falsified immediately. New hypotheses added later get the next available number (H4, H5…). IDs must remain stable so log entries, findings, and conversation references stay consistent.

**Evidence cost order (cheapest first):** logs/metrics → DB queries → code reading → local replication → infrastructure investigation.

For each hypothesis:

1. State it clearly: _"The medication version field is stale because the form caches on load"_
2. Identify the **cheapest evidence that would disprove it** — not confirm it
3. Gather that evidence first
4. Record result in `2_findings.md`: falsified, not-yet-falsified, or inconclusive

When a hypothesis is falsified, note _why_ it was ruled out. This is as valuable as a confirmation.

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

## Phase 5 — Handoff (5_handoff.md)

Fill this in once the fix is agreed on. Structure:

```markdown
# Slack Summary

<2–4 sentence plain-English message suitable for posting in a team channel. Cover: what the bug was, who/what was affected, what caused it, and what the fix is. No jargon, no blame, written for a non-technical reader.>

# Fixes & Remediations

## Immediate fixes

- <change that directly resolves the bug>

## Follow-up remediations

- <anything that would help catch or diagnose this faster next time: improved logging, new alerts, added metrics, better error messages, runbook additions, test coverage, etc.>
```

The remediations list is as important as the fix itself — it turns the investigation into a durable improvement.

## 2_findings.md format

The file has two sections: a **Timeline** at the top, followed by **Hypothesis entries**. Both are updated continuously throughout the investigation.

### Timeline section

```markdown
# Timeline

| UTC | New York | What happened | Exact output |
| --- | --- | --- | --- |
| 2026-07-17 18:43 UTC | 2:43 PM ET | User submits medication form, sees error | `Failed to save: snapshot conflict` |
| 2026-07-17 18:44 UTC | 2:44 PM ET | Page redirects away | — |
```

Add a row every time a new event is discovered — from logs, the user, or the investigation itself. Keep rows in chronological order. The **Exact output** column holds the raw log line, error message, or print statement verbatim; use `—` if there is none.

### Hypothesis entries

```markdown
## H1 [STATUS: investigating | falsified | inconclusive]

**Hypothesis:** <one-sentence hypothesis — never edited after creation> **Evidence needed to falsify:** <what would disprove this> **Evidence gathered:** <what was actually checked> **Result:** falsified | not-yet-falsified | inconclusive **Notes:** <any useful detail>
```

## Common mistakes

| Mistake | Correct approach |
| --- | --- |
| Confirming a hypothesis before trying to falsify it | Always ask: what would prove this wrong? |
| Asking for logs without a timeframe | Always specify start/end timestamps |
| Proposing a fix before replication | Complete `3_steps_to_replicate.md` first |
| Mixing facts and theories in `1_problem.md` | `1_problem.md` = facts only; theories go in `2_findings.md` |
| Checking code before checking data | Start with the cheapest evidence (logs, DB) before reading code |
| Investigating multiple hypotheses in parallel without documenting | One at a time, with results recorded before moving on |
| Leaving findings in the conversation but not the files | Write it down — if it's not in the files, it doesn't exist |
| Implementing a fix during investigation | Only add temporary debug code; fixes go in a separate branch after investigation closes |
