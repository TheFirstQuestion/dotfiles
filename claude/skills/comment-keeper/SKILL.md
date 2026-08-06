---
name: comment-keeper
description: Use when editing existing code, adding new functions, refactoring, or auditing a file for comment accuracy.
---

# Comment Keeper

## Overview

Comments and docs are part of the code. When code changes, its comments must change too. When code is unclear, it needs a comment. Rules 1, 3, 4, and 5 are non-negotiable; Rule 2 (function docs) can be waived by the developer. TODOs and FIXMEs must never be committed.

## Rules

### Rule 1: Keep existing comments in sync

When you change a function's name, parameters, return type, behavior, or **call site** — update every comment and doc block that describes it. A stale comment is worse than no comment: it actively misleads.

**What triggers this rule:**
- Renaming a function or parameter
- Changing a function's signature or return type
- Changing what an inline comment describes (e.g., changing the API endpoint the comment names)
- Refactoring logic that a comment explains
- **Moving a call site** — if you change where or when a function is called (e.g. calling it from `dispose()` instead of a dismiss callback), check the callee's own doc block for lifecycle claims like "when the sheet is dismissed" or "called from X" — they now describe the wrong trigger

**What to update:**
- JSDoc / docstrings above the function
- Inline comments inside the function body
- Any `@param`, `@returns`, `@throws` tags that are now wrong
- **Lifecycle descriptions in callee docs** — any phrase like "when `X` happens", "called from `Y`", "on `Z` event", or "if the user taps back" that describes *when* or *from where* the function is invoked

### Rule 2: Add function-level documentation to new functions

Every new function you write gets a doc block (JSDoc, docstring, etc.) that covers:
- What the function does (one line)
- Each non-obvious parameter and its expected format/range
- The return value and its shape
- Any side effects or thrown errors, if relevant

**Developer can opt out:** If the developer explicitly says not to add function docs (e.g. "no JSDoc", "skip the doc block", "no comments for functions"), respect that for Rule 2 only. Rules 1 and 3 still apply.

**Default is to add docs. Watch for rationalizations to skip them:**
- "We'll document later" — later never comes
- "Just a quick function" — quick functions get called everywhere
- "The name is self-explanatory" — names don't explain parameter formats or edge cases

### Rule 2b: Delete comments when their code is deleted

When you delete a function, block, or line, delete its comments too. A comment with no code is dead weight and causes confusion. This resolves the tension with the global "never remove comments" rule: that rule means don't silently drop a comment that still applies — it does not mean preserve orphaned comments after their code is gone.

### Rule 3: Add clarifying comments for non-obvious code

A comment is required when the WHY is not obvious from reading the code. The test: would a competent developer unfamiliar with this codebase be surprised by this line?

**Always comment:**
- Magic numbers and unexplained constants: `price * 0.9 * 0.95` → what are these rates?
- Business rules embedded in logic: discount tiers, access levels, fee structures
- Workarounds and non-obvious choices: why this approach instead of the obvious one
- Invariants a caller must maintain
- Regex patterns (what does this match?)

**Do not add comments for:**
- What the code mechanically does (the code already says that)
- Standard library calls that do what they say
- Simple conditionals with obvious intent

**Red flags — STOP and add comment:**
- "Clean code speaks for itself" — clean code explains WHAT, not WHY
- "It's obvious" — magic numbers are never obvious to a new reader
- "The variable name explains it" — names don't carry business rationale

### Rule 4: Use consistent comment format

Adapt to the language's standard comment format:

| Language | Doc block | Inline clarification |
|---|---|---|
| TypeScript / JavaScript | `/** ... */` above function | `// above the line` |
| Python | `"""..."""` docstring as first statement | `# above the line` |
| Dart | `/// ` line doc above function | `// above the line` |
| Go | `// FuncName ...` bare comment above function | `// above the line` |
| Swift | `/// ` line doc above function | `// above the line` |

Rules that apply in all languages:
- **Clarifying comments go above the line** they explain, not end-of-line
- **Never end-of-line** for multi-word explanations — they wrap and become unreadable
- Exception: very short labels (e.g. `// 50% staff benefit`) are acceptable end-of-line when aligning a column of similar lines

```typescript
// ✅ Above the line
// Exponential backoff: 100ms base, doubles each attempt
await delay(Math.pow(2, attempt) * 100);

// ❌ End-of-line for a real explanation
await delay(Math.pow(2, attempt) * 100); // Exponential backoff: 100ms base, doubles each attempt
```

### Rule 5: No TODOs or FIXMEs in committed code

`TODO` and `FIXME` comments must not be committed. They signal unfinished work and rot immediately — they accumulate, are never revisited, and mislead future readers about intent.

**Instead:**
- If the work needs doing: open a ticket and reference it in a comment, or finish it now
- If it's a known limitation: write a comment that explains the constraint, not a placeholder

```typescript
// ❌ TODO: handle the null case
// ❌ FIXME: this breaks for empty arrays

// ✅ Constraint explained, no placeholder
// Caller is responsible for ensuring userId is non-null before calling this function
// ✅ Tracked work referenced
// Null handling not yet implemented — see PROJ-456
```

The pre-commit check will block commits containing new `TODO` or `FIXME` lines. Remove or replace them before committing.

### Rule 6: Add reference links for workarounds and external decisions

When code works around a bug, implements a spec, or was shaped by a Stack Overflow answer or GitHub issue, leave a link comment. A future reader who sees unusual code will search for why — give them the answer directly.

**Always link when:**
- Working around a library/browser/OS bug
- Implementing an algorithm from a paper, RFC, or external source
- Following a non-obvious approach suggested by an issue or discussion

```typescript
// ✅ Link to the root cause
// Safari ignores pointer-events on SVG children — workaround via wrapper div
// https://bugs.webkit.org/show_bug.cgi?id=64897
div.style.pointerEvents = 'none';

// ✅ Algorithm source
// Luhn algorithm for credit card validation
// https://en.wikipedia.org/wiki/Luhn_algorithm
```

### Rule 7: Add file-level headers where needed

Two cases warrant a comment at the top of the file:

**Non-obvious module purpose** — when the filename alone doesn't communicate what the file is for or why it exists:
```typescript
// Middleware chain for request authentication.
// All routes under /api pass through this before reaching handlers.
```

**Complex exports** — when a file exports many things and a reader would benefit from a map:
```typescript
// Discount calculation utilities.
// Exports: applyDiscount, calculateTax, formatCurrency, DISCOUNT_TIERS
```

Do NOT add a file header when:
- The filename and directory make the purpose obvious (`UserCard.tsx`, `auth.middleware.ts`)
- The file only exports one thing

## Audit Workflow

When asked to audit a file, or as part of pre-commit review:

### Step 1 — Collect the symbol list

Read the diff (or the full file if auditing directly). Extract every named symbol that was **added, changed, or deleted**:

- Functions and methods (including private/internal)
- Types, interfaces, and type aliases
- Enums and enum members
- Exported constants and variables with non-obvious values
- Classes

**Do not skip private or internal symbols.** They appear in comments throughout the codebase too.

### Step 2 — Per-symbol checklist

For each symbol, run through every question. A "no" on any question is a finding that must be fixed before moving on.

#### 2a — Own doc block (at the definition site)

| # | Question | Applies to |
|---|---|---|
| 1 | Does it have a doc block? | All exported symbols; all functions regardless of visibility |
| 2 | Does the doc block's description match current behavior? | Any symbol with an existing doc block |
| 3 | Is every parameter documented with name, type, and purpose? | Functions/methods |
| 4 | Is the return type and shape described? | Functions/methods that return non-void |
| 5 | Are thrown errors or rejected promises documented? | Functions/methods that throw |
| 6 | Are enum members individually documented if their meaning isn't obvious from the name? | Enums |
| 7 | Are type/interface fields documented if non-obvious? | Types, interfaces |
| 8 | Is the constant's value or allowed range explained? | Constants with magic values |

#### 2b — Inline comments in the body

| # | Question |
|---|---|
| 9 | Do all inline comments still describe what the adjacent code does? |
| 10 | Are magic numbers and unexplained constants commented? |
| 11 | Are business rules embedded in logic explained (why, not just what)? |
| 12 | Are workarounds linked to a bug, issue, or source? |
| 13 | Are there any `TODO` or `FIXME` comments? (must be removed or replaced) |
| 14 | Are there commented-out blocks without an explanation of why? |

#### 2c — Cross-codebase references

For each symbol name, find every comment mentioning it across the repo:

```bash
~/.claude/skills/comment-keeper/find-symbol-refs.sh <symbol-name>
```

**Also search architecture and design docs** (`.claude/architecture.md`, `ARCHITECTURE.md`, `docs/`, `README.md`) — these often contain lifecycle descriptions that go stale when call sites move. The grep script covers source files; scan docs separately if the change touches a public API or lifecycle boundary.

For each hit:

| # | Question |
|---|---|
| 15 | Does the comment's description of this symbol still match what the symbol actually does? |
| 16 | If the symbol was renamed, does the comment still use the old name? |
| 17 | If the symbol was deleted, is this comment now orphaned (referring to something that no longer exists)? |
| 18 | Does the comment contain a lifecycle claim ("when X happens", "called from Y", "on Z event", "if the user taps back") that no longer matches the actual call site? |

Fix every stale, orphaned, or mismatched reference found.

#### 2d — Behavioral change propagation (functions only)

If a function's **logic changed** (not just its name or signature), do this additional pass:

1. Write a one-sentence summary of what the function did **before** and what it does **now**. If you can't articulate the difference, re-read the diff until you can — this sentence is the lens for the entire pass.

2. In the `find-symbol-refs.sh` output, identify every comment that **describes the function's behavior** (not just names it). These are comments like:
   - "// calls `X` to validate the token before returning"
   - "// `X` always returns sorted results"
   - "Uses `X` to normalize the input"

3. For each behavioral description, ask:

| # | Question |
|---|---|
| 21 | Does the description still hold under the new logic? |
| 22 | Does the description name a side effect, invariant, or guarantee that the new logic no longer provides? |
| 23 | Does the description omit a new behavior that callers would need to know about? |

**Note:** These comments often do not use the exact function name — they may paraphrase the function's purpose. The grep output is a starting point; also read the calling functions identified in the diff and check their surrounding comments.

### Step 3 — File-level checks

After all per-symbol checks are done:

| # | Question |
|---|---|
| 19 | Does the file need a header? (non-obvious module purpose, or many exports) |
| 20 | Does the file have a header that's now wrong or outdated? |

### Step 4 — Report and fix

List every finding by symbol, question number, and file:line. Fix all of them. Do not leave findings open.

## Quick Reference

| Situation | Action |
|---|---|
| Moved a call site (changed where/when a function is called) | Check callee's doc block for lifecycle claims ("when X", "called from Y", "if the user taps back") — update to match new trigger; also search architecture docs |
| Renamed a function | Update doc block name + description |
| Changed param type/name | Update `@param` tags and inline refs |
| Changed what a comment describes | Rewrite that comment |
| Deleted a function or block | Delete its comments too |
| Writing a new function | Add block doc above the function (language-appropriate format) |
| Writing a new function, developer said no docs | Skip doc block; still add above-line inline comments if WHY is non-obvious |
| Magic number in logic | Add above-line comment: what it represents |
| Business rule in a conditional | Add above-line comment: why this rule exists |
| Developer says "don't add comments" | Add above-line comments if the WHY is non-obvious (Rule 3 still applies) |
| Workaround for a bug or external decision | Add above-line comment with a link to the source |
| TODO or FIXME found in changed code | Replace with a real comment or a ticket reference — do not commit |
| New file with non-obvious purpose | Add a one-line file-level header |
| New file with many exports | Add a file-level header listing what it exports |
| Asked to audit a file | Follow the Audit Workflow |

## Common Mistakes

**Keeping a stale doc block after renaming**
```typescript
// ❌ Function renamed but JSDoc wasn't updated
/**
 * Fetches a user from the API.
 * @param request - The UserRequest object
 */
async function loadUserProfile(userId: string): Promise<User> { ... }

// ✅ JSDoc matches the actual function
/**
 * Loads a user profile from the API.
 * @param userId - The user's unique ID
 */
async function loadUserProfile(userId: string): Promise<User> { ... }
```

**Skipping docs by default (when developer hasn't opted out)**
```typescript
// ❌ No doc block added without developer asking to skip — what currency code format? what does it return?
export function formatCurrency(amount: number, currencyCode: string): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: currencyCode }).format(amount);
}

// ✅ Default: doc block added
/**
 * Formats a number as a locale-aware currency string.
 * @param amount - The numeric amount to format
 * @param currencyCode - ISO 4217 code (e.g. 'USD', 'EUR')
 * @returns Formatted string, e.g. '$1,234.56'
 */
export function formatCurrency(amount: number, currencyCode: string): string { ... }

// ✅ Also fine: developer explicitly said "no function docs"
export function formatCurrency(amount: number, currencyCode: string): string { ... }
```

**Letting "clean code" excuse unexplained business logic**
```typescript
// ❌ Why 0.9? Why 0.95? Why 0.5? A new developer has no idea.
if (userType === 'premium') return price * 0.9 * 0.95;
if (userType === 'staff') return price * 0.5;
return price * 0.9;

// ✅ The numbers are explained — short end-of-line labels acceptable here because they're an aligned column
if (userType === 'premium') return price * 0.9 * 0.95; // 10% loyalty + 5% upgrade discount
if (userType === 'staff') return price * 0.5;           // 50% staff benefit
return price * 0.9;                                     // standard 10% discount
```
