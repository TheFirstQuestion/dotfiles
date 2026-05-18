---
name: update-pr-description
description: Use when updating a pull request description to reflect what actually landed.
argument-hint: [pr-url-or-number]
---

## Goal

Produce an accurate, well-structured PR description that reflects the actual implementation, references all relevant context (tickets, stacked PRs), and records any meaningful changes from the original description in a Changelog section.

## Step 0 — Identify the PR

If an argument was provided (URL or number), use that PR. Otherwise detect the current branch's PR:
```
gh pr view --json number,url,title,body,headRefName,baseRefName 2>/dev/null
```

If no PR is found, ask the user for a PR number or URL and stop.

## Step 1 — Gather all context

Run these in parallel:

**PR data:**
```
gh pr view <number> --json number,url,title,body,headRefName,baseRefName,commits
gh pr diff <number>
```

**Stacked / dependent PRs** — search for other open PRs in the same repo that reference this PR's branch or number, or that this PR's branch was based on:
```
gh pr list --json number,url,title,headRefName,baseRefName,body --state open
```
A PR is "stacked" if:
- Its `baseRefName` matches this PR's `headRefName` (this PR is a parent)
- Its `headRefName` matches this PR's `baseRefName` (this PR is a child)
- Its body or title mentions this PR's number or branch name

**PR template** — check for a template in the repo:
```
ls .github/PULL_REQUEST_TEMPLATE* 2>/dev/null
ls .github/pull_request_template* 2>/dev/null
ls docs/pull_request_template* 2>/dev/null
```
If a template exists, read it. If multiple exist, pick the most generic one (or ask the user).

**Commit messages:**
```
gh pr view <number> --json commits -q '.commits[].messageHeadline'
```

## Step 2 — Extract ticket IDs

Scan all of the following for ticket ID patterns (`MOB-123`, `ENG-456`, `PROJ-789`, etc.):
- Branch name
- PR title
- Existing PR body
- Commit messages

For each unique ticket ID found, construct the URL as:
```
https://dimerhealth-cast.monday.com/item/<ticket-id>
```
Example: `MOB-230` → `[MOB-230](https://dimerhealth-cast.monday.com/item/MOB-230)`

If the existing PR body already contains a different link for that ticket ID, prefer the existing URL (it may be a direct board item ID rather than the slug).

List all ticket IDs and their links — these must appear in the description.

## Step 3 — Analyze the diff

Read the diff carefully. Produce a factual summary of what the PR actually does:
- What changed (files, modules, patterns)
- What the intent is (inferred from commits, ticket IDs, and branch name)
- Any notable implementation decisions (e.g. "uses a header rather than a query param", "validates before creating resources", "caches by composite key")

This is the ground truth the description must reflect.

## Step 4 — Detect description drift

Compare the existing PR body against your diff analysis from Step 3. Identify any statements in the existing description that are:
- **Inaccurate** — describes something differently from how it was actually implemented
- **Stale** — references an approach that was changed mid-PR
- **Missing** — significant implementation details present in the diff but absent from the description

Collect each drift item as a Changelog entry in the form:
> `Originally described X; implementation uses Y instead.`

If the description is accurate and complete, the Changelog will be empty (but the section still appears — see Step 5).

## Step 5 — Write the new description

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
<entries from Step 4, or "No changes to description.">
```

**Rules for every description:**
- Every ticket ID found in Step 2 must appear, linked if a URL is known
- Every stacked/dependent PR must be listed with its number, title, and URL
- The Changelog section must always be present — append new entries, never remove old ones
- Do not describe things the diff doesn't show — accuracy over completeness
- Write in present tense ("adds", "validates", "returns"), not past tense

## Step 6 — Present and confirm

Show the user the proposed new description as a markdown preview. Show a diff of what changed vs. the current description if the existing body is non-trivial.

Ask: **"Does this look right? (yes / edit / cancel)"**

- If **edit**: ask what to change, revise, and ask again.
- If **cancel**: stop without posting.
- If **yes**: proceed.

## Step 7 — Update the PR

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
