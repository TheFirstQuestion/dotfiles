---
name: update-pr-description
description: Use when updating a pull request description to reflect what actually landed.
argument-hint: [pr-url-or-number]
---

## Goal

Produce an accurate, well-structured PR description that reflects the actual implementation, references all relevant context (tickets, stacked PRs), and records any meaningful changes from the original description in a Changelog section.

## Step 0 — Fetch all PR data

Run the `pr-data` script (lives alongside this skill at `~/.claude/skills/update-pr-description/pr-data.sh`) to fetch all data in a single call:

```
~/.claude/skills/update-pr-description/pr-data.sh [<PR-number-or-URL>]
```

If an argument was provided (URL or number), pass it through. Otherwise run with no argument — the script will auto-detect the current branch's PR.

If the script exits with a non-zero status or its output contains `{"error":...}`, report the error to the user and stop.

The script outputs a JSON object with these keys:
- `pr` — PR metadata: `number`, `url`, `title`, `body`, `headRefName`, `baseRefName`, `author`
- `commits` — flat array of commit message headlines
- `template` — PR template contents as a string, or `null` if none found
- `stacked_prs` — array of related open PRs, each with `number`, `url`, `title`, `headRefName`, `baseRefName`, and `relationship` (`"parent"`, `"child"`, or `"mentioned"`)
- `diff_path` — path to a temp file containing the full PR diff; read this file in Step 2

## Step 1 — Extract ticket IDs

Run:
```bash
~/.claude/skills/update-pr-description/extract-tickets.sh [<number-or-url>]
```

Use the JSON array output directly. Each element has `id` and `url`. If the array is empty, the Tickets section of the description gets "None".

## Step 2 — Analyze the diff

Read the diff carefully. Produce a factual summary of what the PR actually does:
- What changed (files, modules, patterns)
- What the intent is (inferred from commits, ticket IDs, and branch name)
- Any notable implementation decisions (e.g. "uses a header rather than a query param", "validates before creating resources", "caches by composite key")

This is the ground truth the description must reflect.

## Step 3 — Detect description drift

Compare the existing PR body against your diff analysis from Step 2. Identify any statements in the existing description that are:
- **Inaccurate** — describes something differently from how it was actually implemented
- **Stale** — references an approach that was changed mid-PR
- **Missing** — significant implementation details present in the diff but absent from the description

Collect each drift item as a Changelog entry in the form:
> `Originally described X; implementation uses Y instead.`

If the description is accurate and complete, the Changelog will be empty (but the section still appears — see Step 4).

## Step 4 — Write the new description

**If a PR template exists:** fill it in exactly, preserving all section headings. Do not add or remove sections.

**If no template exists:** mimic the structure of the existing description. If the existing description has no structure, use this default:

```
## Summary
<what this PR does, 2–4 sentences>

## Ticket(s)
<linked ticket IDs>

## Implementation notes
<notable decisions, approach, anything a reviewer should know>

## Stacked PRs
<linked stacked PRs, or "None">

## Testing
<how to verify this change>

## Changelog
<entries from Step 3, or "No changes to description.">
```

**Rules for every description:**
- Every ticket ID found in Step 1 must appear, linked if a URL is known
- Every stacked/dependent PR must be listed with its number, title, and URL
- The Changelog section must always be present — append new entries, never remove old ones
- Do not describe things the diff doesn't show — accuracy over completeness
- Write in present tense ("adds", "validates", "returns"), not past tense

## Step 5 — Update the PR

**Do not ask for confirmation — run immediately.** The `gh pr edit` permission prompt is the gate.

```
gh pr edit <number> --body "<new description>"
```

Confirm the update succeeded by re-fetching:
```
gh pr view <number> --json body -q '.body' | head -5
```

## Common Mistakes

- Editing before reading the full diff — description will miss or misrepresent changes
- Removing existing Changelog entries — history is lost; always append, never delete
- Inventing details not present in the diff — accuracy over completeness
