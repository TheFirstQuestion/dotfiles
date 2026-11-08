# Local custom lint rules (Semgrep)

Personal lint rules that show up as Information-level diagnostics in
VSCode/VSCodium/Cursor, on any repo you open, on any language — without
writing anything into those repos. This works because the rules are wired
through your VSCode **User** settings (`vscode/settings.json` in this
repo), not any project's workspace settings. Coworkers on the same repos
see nothing.

## One-time setup

1. Install the Semgrep CLI: `brew install semgrep`
   (confirmed: only used for authoring/testing rules from the terminal —
   the VSCode extension ships and runs its own separate bundled binary at
   runtime and never touches this one. Kept because it's a stable `semgrep`
   PATH entry to script against; the bundled binary lives at a
   version-specific path inside the extension's install directory.)
2. Install the "Semgrep" extension (publisher: Semgrep, id
   `Semgrep.semgrep`) in whichever editor(s) you use:
   ```sh
   code --install-extension Semgrep.semgrep       # VS Code
   codium --install-extension Semgrep.semgrep     # VSCodium
   cursor --install-extension Semgrep.semgrep      # Cursor
   ```
   (Available on both the VS Code Marketplace and Open VSX, so this works
   for all three editors.)
3. Reload the editor. Diagnostics from `semgrep/rules/` should now appear
   inline in any file you open, in any repo.

## How it's wired

- `vscode/settings.json` sets `semgrep.scan.configuration` to
  `~/dotfiles/semgrep/rules` — the extension always scans against this
  rule pack, everywhere.
- `semgrep.scan.onlyGitDirty` is set to `false`, because the extension
  defaults to scanning only lines changed since the last commit; we want
  it to scan full files.
- `semgrep.useExperimentalLS` is set to `true`. **This is required, not
  optional** — see Known Issue below.

## Known issue: the default ("legacy") language server ignores your settings

As shipped (extension 1.17.0 / bundled binary 1.176.0), the extension's
default "legacy" language server silently ignores `scan.configuration` and
`scan.onlyGitDirty` and falls back to scanning with Semgrep's large default
community ruleset instead of this repo's rule pack.

Root cause (confirmed by reading `semgrep/semgrep`'s
`src/lsp_legacy/requests/Legacy_initialize_request.ml` and
`Legacy_user_settings.ml`, and by direct comparison against invoking the
extension's own bundled binary in plain `scan` mode, which works
correctly): the client sends a `secrets` field inside the `scan` settings
object (from a real `semgrep.scan.secrets` package.json setting), but the
server's `Legacy_user_settings.t` OCaml type has no `secrets` field and
derives its JSON parser strictly — one unrecognized field fails parsing of
the *entire* settings object, silently reverting to defaults (empty
`configuration`, `onlyGitDirty: true`) with no visible error.

Fix: `semgrep.useExperimentalLS: true` switches to the newer language
server implementation, which doesn't have this bug. Already set in
`vscode/settings.json` — if diagnostics ever stop appearing again after an
extension update, check whether this setting is still present before
re-debugging from scratch, and check the "Semgrep" client output channel's
`Semgrep Initialization Options :=` log line against what the target file
actually scans with (visible in the "Semgrep" server output channel's rule
count) if it recurs in a different form.

## Adding a new rule

1. Create or edit a `.yml` file in `semgrep/rules/`. Every rule should set
   `severity: INFO` unless you deliberately want it louder.
2. Create a same-named test target file (e.g. `foo.yml` + `foo.js`; Dart uses `foo.test.dart`) with `// ruleid: <rule-id>` above lines that should match and `// ok: <rule-id>` above lines that should not.
3. Validate: `semgrep --test --config semgrep/rules/ semgrep/rules/`
4. Open a matching file in VSCode and confirm the diagnostic appears.

Use `pattern:` (or `pattern-either:`) for structural/AST-aware rules
scoped to specific languages. Use `pattern-regex:` under `languages:
[generic]` for plain text/string matching that should apply to any file,
regardless of syntax.

### Narrowing what gets highlighted

By default a match's reported range (and therefore the VSCode diagnostic's
squiggle) spans the *entire* matched construct — for a function-definition
rule, that's the whole function including its body. To narrow it, add
`focus-metavariable: $SOME_MVAR` as a sibling item inside a `patterns:`
list (not as a key alongside a bare top-level `pattern:` — it's silently
ignored there). Two gotchas found empirically, verified against the real
CLI before shipping:

- `focus-metavariable` accepts a list (`[$A, $B]`), but that does **not**
  produce one match spanning from `$A` to `$B` — it produces two separate,
  duplicate findings, one focused on each. Avoid unless you actually want
  duplicates.
- If a rule's `pattern-either` has alternatives that bind different
  metavariable names (e.g. a named function binds `$NAME` but an arrow
  function doesn't), a `focus-metavariable` placed at the outer level
  (sibling to the whole `pattern-either`) **silently drops every
  alternative that doesn't bind it** — not a graceful fallback to
  full-range highlighting. Instead, give each alternative its own nested
  `patterns:` block with its own `focus-metavariable:` — this works
  correctly and lets each alternative highlight something different (see
  `three-param-limit.yml`'s JS/TS rule: named functions focus on `$NAME`,
  arrow functions — which have no name to bind — focus on `$A`, the first
  parameter, instead).

### Counting body length ("more than N statements")

To flag a function/loop/if body with more than N statements, bind the body as a statement-list metavariable (`$...BODY`) and gate the match with a sibling `metavariable-pattern` whose nested `pattern` is a sequence of N+1 single-statement metavariables followed by an ellipsis metavariable, e.g. `$S1; $S2; $S3; $...REST` for "more than 2" in JS/TS (semicolon-separated), or the newline-separated equivalent for Python (see `long-function-body.yml`, `long-block-body.yml`). This re-parses the bound body text as its own program and requires it to contain at least N+1 statements before the trailing ellipsis can match the rest — a true statement count, immune to how many lines any individual statement's formatting spans.

Don't use a line-counting `pattern-regex` (e.g. `(?s)^(?:[^\n]*\n){N,}`) for this — it was the original approach here and is wrong: a single statement reformatted across many lines (e.g. a function call with one argument per line) inflates the line count without adding any real complexity, causing false positives. Statement count is what the rule is actually trying to measure. Both test files include a single multi-line-statement case specifically to guard against regressing to the line-counting regex.

### Why body-length rules focus on the condition, not the `if`/`while`/`for` keyword

You cannot `focus-metavariable` on a bare keyword — there's no metavariable bound to it. The tempting workaround, a sibling `pattern-regex: \b(if|while|for)\b`, is unsafe: that regex is matched against the *whole file*, then intersected with the structural match purely by range containment — not scoped to the specific node. A long `if`/`while`/`for` that contains a *nested*, short `if`/`while`/`for` will spuriously also flag the nested one's keyword, because its keyword text falls inside the outer (passing) match's range too. No combination of `pattern-not-inside` or regex anchors (`^`, `\A`) fixes this — confirmed empirically — because the regex is evaluated file-wide, not against the matched node's own text. `long-block-body.yml` instead focuses on the condition/iterable metavariable (`$COND` / `$ITER`), which is bound per-match and immune to this. The `long-block-body.test.js`/`.test.py` files include a nested-`if`-inside-long-`if` case specifically to guard against regressing to the keyword-regex approach.

## Dart / Flutter

Four of the five rules also have a `-dart` variant (`law-of-demeter`, `three-param-limit`, `long-block-body`, `pure-function`), tested by `*.test.dart` files. Dart's Semgrep support is noticeably more limited than JS/Python's, so several techniques from the sections above don't carry over. Everything below was verified empirically against Semgrep 1.176.0; re-check after a Semgrep upgrade, since some of these may get fixed.

### `long-function-body` has no Dart variant (on purpose)

Counting "more than 20 statements" needs 21 `$S1; $S2; ...` metavariables in a single pattern, and for Dart that is exponentially slow: even one 21-statement function in an otherwise empty file hits Semgrep's per-rule timeout (~5s), and the rule then silently reports nothing. Scaling by statement count (n=6 ≈ 0.5s, n=10 ≈ 2s, n≥14 times out) also ruled out anonymous `$_` metavariables and dropping the trailing `...`. `long-block-body-dart` uses n=6 and is fast enough. If you want a Dart long-function rule anyway, the only cheap option found is a `metavariable-regex` on the body that counts `;` (counts nested statements and `for(;;)` headers too, so it measures "total statements," not top-level ones) — not shipped because it silently changes what the rule means.

### `$...BODY` doesn't parse in Dart blocks

`if ($COND) { $...BODY }` and `$NAME(...) { $...BODY }` are rejected as invalid Dart patterns, so the JS/Python technique of binding the body and gating it with `metavariable-pattern` is unavailable. Write statements directly in the pattern instead (`$S1;` `$S2;` ... each on its own line, then a trailing `...`). Dart statement patterns need the trailing `;` (`print(...);`), but inside the deep-match operator `<... ...>` they must not have one.

### `impure-function-dart` highlights the side effect, not the function name

Because the body can't be bound, the rule matches the side-effecting expression itself with `pattern-inside` on the enclosing function. This works at any nesting depth (inside `if`/`for`/closures) but `focus-metavariable` on a metavariable bound only by `pattern-inside` silently matches nothing, so the squiggle lands on the `print(...)` / `this.x = ...` rather than the function's name, and a function with three side effects gets three squiggles. Dart code usually mutates fields without `this.`, so private-field (`_name`) assignments, `++`/`--`, and collection mutations are matched by a `metavariable-regex: ^_` on the target instead.

### `three-param-limit-dart` counts named parameters too

`{...}` inside a Dart parameter-list pattern acts as a wildcard that matches any parameter list (even `(int a, int b, int c)`), and `[optional]` positional groups can't be pattern-matched at all, so there's no way to count positional parameters only. The rule therefore flattens everything and flags any function with more than 3 parameters, including `void f({required a, required b, required c, required d})`. Constructors (including Flutter widget constructors with many named parameters) aren't matched by the function patterns, so widgets aren't flagged; `[optional]` groups are not counted.

### `law-of-demeter-dart` and null-aware calls

`$X.$M1(...).$M2(...)` already matches `a?.b().c()` and `a!.b().c()`, but `a.b()?.c()` needs its own alternative. Cascades (`a.b()..c()..d()`) and property-only chains are not flagged. As in JS, this flags fluent chains such as `xs.where(...).toList()` and Flutter idioms like `Navigator.of(context).push(...)`.
