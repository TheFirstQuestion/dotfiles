---
name: self-review-requirements
description: Review and improve documentation, requirements analysis, specifications, and reasoning-heavy outputs before final delivery.
---

# Self-review requirements skill

Use this skill before finalizing any documentation, requirements analysis, specification, architecture note, task breakdown, or decision memo.

## Goal

Improve the answer without involving the user unless a real decision is required.

Do not show intermediate drafts to the user. Iterate internally until no fixable issues remain.

## Review loop

Repeat the following loop until no fixable issues remain:

1. Check the draft for:
   - logical contradictions
   - unsupported conclusions
   - missing assumptions
   - requirements that conflict with each other
   - ambiguous wording that can be clarified from context
   - gaps between problem, constraints, and proposed solution
   - acceptance criteria that do not match requirements
   - invented facts or details not present in the context
   - overconfident language where evidence is weak
   - duplicated or inconsistent terminology
   - hidden decisions disguised as implementation details

2. Classify each issue as one of:

   A. Auto-fixable:
   - wording clarity
   - structure
   - consistency
   - deduplication
   - obvious missing links between existing facts
   - explicit assumptions derived from context
   - correcting contradictions where context clearly resolves them

   B. Requires user decision:
   - choosing between valid business options
   - changing scope
   - defining priority
   - deciding trade-offs
   - confirming domain-specific intent not present in context
   - selecting acceptance criteria where multiple interpretations are valid

3. Fix every Auto-fixable issue.

4. Preserve every Requires user decision issue for the final “Needs user decision” section.

5. Re-review the updated version from scratch.

## Stopping rule

Stop only when:

- no Auto-fixable issues remain;
- all unresolved issues genuinely require user decision;
- the final answer is internally consistent;
- the answer does not hide uncertainty;
- the answer does not ask the user to decide anything Claude can safely resolve from existing context.

## Final output format

Return:

1. Final cleaned result.
2. If needed, a short section:

   `Needs user decision`

   Include only decisions that cannot be made from the provided context.
