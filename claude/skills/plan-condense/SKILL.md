---
name: plan-condense
description: Condense an implementation plan file to pure action items — strips rationale/"why" notes and verbose wording. Aborts without modifying the file if it still contains unresolved multiple-choice decisions.
---

# Plan Condense

Rewrites an implementation plan file in place so it contains only precise, actionable steps.

## Step 1 — Resolve the file path

The argument passed to this command is: `$ARGUMENTS`

- If `$ARGUMENTS` is empty, look in `temp/` in the repo.

If there's nothing there, output:

> **Error:** No file path provided. Usage: `/plan-condense <path-to-plan.md>`

Then stop.

- If the file does not exist at that path, output:

  > **Error:** File not found: `<path>`

  Then stop.

Read the full file before doing anything else.

## Step 2 — Check for unresolved multiple choices

Read the entire plan looking for any point where it presents more than one viable path forward without having picked one. Signals include (not exhaustive — use judgment, not pattern matching):

- Explicit alternatives: "Option A / Option B", "Option 1 / Option 2", "Alternative:", "Approach 1 vs Approach 2"
- Open decision language: "we could either X or Y", "choose between", "should we X or Y?", "TBD", "[decision needed]", "pending decision"
- Pros/cons lists comparing competing approaches to the same step without a stated resolution
- Questions addressed to the reader that the plan itself does not answer

Do NOT flag:

- Ordinary conditional logic in the implementation itself (e.g. "if the field is null, return early") — this is not a planning-level choice.
- A choice the plan explicitly resolves right after presenting it (e.g. "Option A vs Option B — going with Option A because..."). Only the resolved option is in scope; the rejected option's text gets removed in Step 3, not treated as unresolved.

If any unresolved multiple-choice decision is found:

- Make NO edits to the file.
- Output exactly this, listing every unresolved decision found (not just the first one):

  > **Aborted:** This plan still contains unresolved choices that need to be decided before it can be condensed. Resolve the following first:
  >
  > - `<quote or paraphrase of the ambiguous section>`
  > - ...

- Then stop. Do not guess, pick, or default to any option.

## Step 3 — Condense the plan

Only reached if Step 2 found nothing unresolved. Rewrite the file with these rules:

1. **Remove rationale.** Delete any sentence or clause explaining _why_ a step is being done — background, motivation, justification. Keep only _what_ to do.
2. **Remove resolved alternatives.** For any choice the plan already resolved, delete the rejected option(s) and the comparison text; keep only the chosen path, stated as a direct instruction.
3. **Condense wording.** Rewrite remaining content as short, direct, imperative statements. No hedging, no filler, no restating context the reader already has. Prefer bullet/numbered lists over prose.
4. **Keep what's load-bearing.** Preserve exact file paths, function/class names, command invocations, ordering, and any technical specifics needed to execute the plan correctly.
5. **Keep structure.** Preserve headings that organize the plan into steps/sections; condense their content, don't flatten the document into a single blob.

Overwrite the original file at the resolved path with the condensed version.

## Step 4 — Report

Output a short confirmation only:

> Condensed `<path>`.
