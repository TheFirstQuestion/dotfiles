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
2. Create a same-named test target file (e.g. `foo.yml` + `foo.js`) with
   `// ruleid: <rule-id>` above lines that should match and `// ok:
   <rule-id>` above lines that should not.
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
