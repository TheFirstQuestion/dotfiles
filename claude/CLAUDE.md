# Global Claude Instructions

## Code editing rules

- Never remove existing comments from code, even if they appear redundant or obvious.
- Code must be clean (no errors, no lint warnings) before a task is considered done. Keep editing until `flutter analyze` (or the equivalent linter for the project) passes cleanly.

## GitHub rules

- Never post comments on PRs (including replies to review comments) without explicit user approval. This includes `gh api` calls to comment endpoints — comments are not pre-approved even though other `gh api` calls are.
- All PR comments (replies to review comments) must end with the line `Written with Claude Code`.

## Git rules

- Never attempt to commit unless the user explicitly asks. Always run /review and /simplify before committing.
- Always commit to a feature branch. Never commit directly to main.
- Ensure Claude local config files (e.g. `.claude/`, `CLAUDE.md`, `.mcp.json`) are listed in `.gitignore` before committing. Never push these files to GitHub.
- When committing, always stage with `git add .` — never cherry-pick individual files unless the user explicitly asks you to.
- All commit messages must include the line `Written with Claude Code` to indicate Claude's involvement.
- All tests must pass, lint must be clean, and code must be formatted before committing. Run the formatter, linter, and test suite before every commit and fix any failures first.
- Before committing, remove unused code. Commented-out code must have an inline comment explaining why it is commented out but not deleted (e.g. a ticket number, a known reason it may be re-enabled). Commented-out code with no explanation is not allowed.
