# Global Claude Instructions

## Language

Always use US English in all responses and written content.

## Code exploration

When exploring or searching code, always use `code-review-graph` (CRG) if it is available as an MCP tool in the current project. Fall back to `grep` / `find` only if CRG is not available.

If CRG is not available in a project, tell the user and offer to help them set it up before proceeding.

If CRG returns no results, only a handful of indexed files, or results that seem stale (missing files or symbols that clearly exist), rebuild the graph immediately by running `code-review-graph build`, then retry the query. Do not ask — the build is idempotent. Never fall back to grep while CRG is available.

## Debugging

- When in doubt, add a bunch of debugging print statements and watch it run (remember to remove them later!).

- Always prefix debug `console.log` / `print` statements with `====>` so they're easy to spot and grep for in logs.

## iOS Simulator

- Do not navigate the simulator by tapping through screens — it is slow and error-prone. Instead, ask the user which specific screen to land on and they will navigate there directly.

## Code editing rules

- Never remove existing comments from code, even if they appear redundant or obvious.
- Code must be clean (no errors, no lint warnings) before a task is considered done. Keep editing until `flutter analyze` (or the equivalent linter for the project) passes cleanly.

## GitHub rules

- Always use the `gh` CLI for all GitHub operations (PRs, issues, comments, reviews, etc.). Never use the `mcp__github__*` tools.
- All PR comments (replies to review comments) must end with the line `Written with Claude Code`.


## Claude scripts (`~/.claude/scripts/`)

These scripts are pre-allowed and should be used instead of inline shell equivalents to avoid permission prompts.

| Script | Usage | Purpose |
|--------|-------|---------|
| `git-commit.sh` | `~/.claude/scripts/git-commit.sh "<subject>" "[body]"` | Commit with `Written with Claude Code` footer baked in |
| `git-context.sh` | `~/.claude/scripts/git-context.sh` | Print GIT_DIR, GIT_COMMON_DIR, and current branch — use to detect if inside a worktree (GIT_DIR ≠ GIT_COMMON) |
| `add-allowed-directory.sh` | `~/.claude/scripts/add-allowed-directory.sh [path]` | Add a directory to `permissions.additionalDirectories` in `~/.claude/settings.local.json` (gitignored) so Claude can access it without permission prompts. Defaults to `pwd`. Idempotent. |
| `git-security-scan.sh` | `~/.claude/scripts/git-security-scan.sh` | Scan staged diff for hardcoded secrets and staged `.env` files; exit 1 if found |
| `pr-comments-init.sh` | `~/.claude/scripts/pr-comments-init.sh <progress-file> <pr-number> "<repo>" <total>` | Initialize a PR comments progress file |
| `pr-comments-add-reply.sh` | `~/.claude/scripts/pr-comments-add-reply.sh <progress-file> <comment-id> <reply-type> "<body>"` | Append a reply to the PR comments progress file |
| `pr-comments-update-reply.sh` | `~/.claude/scripts/pr-comments-update-reply.sh <progress-file> <comment-id> "<new-body>"` | Update the body of an existing pending reply |
| `post-pr-replies.sh` | `~/.claude/scripts/post-pr-replies.sh <progress-file>` | Post all pending replies from the progress file to GitHub in one call |
| `list-skills.sh` | `~/.claude/scripts/list-skills.sh` | List available skills from user/project skills dirs and installed plugins — use this instead of the raw compound command to avoid permission prompts |
| `check-conflicts.sh` | `~/.claude/scripts/check-conflicts.sh [base-branch]` | Check for merge conflicts between HEAD and base branch (default: `origin/main`). Exits 0 if clean, 1 if conflicts found. Use instead of the inline `git merge-tree` command substitution. |
| `find-symbol-refs.sh` | `~/.claude/skills/comment-keeper/find-symbol-refs.sh <symbol> [repo-root]` | Find all comment lines mentioning a symbol across the codebase. Use during comment-keeper audits to find stale cross-codebase references. |
| `clean-up-discover-repos.sh` | `~/.claude/scripts/clean-up-discover-repos.sh [dir]` | Print each immediate subdirectory of DIR (default: cwd) that is a git repo. Use during the clean-up skill Step 0 when running from a parent folder. |
| `clean-up-gather-state.sh` | `~/.claude/scripts/clean-up-gather-state.sh <repo-path>` | Print worktree list, branches with upstream tracking, last-commit dates, HEAD, and remote URL for a repo. Use during the clean-up skill Step 1 gather phase. |
| `sync-mcp-permissions.sh` | `~/.claude/scripts/sync-mcp-permissions.sh [project-root]` | Merge `mcp__*` allow entries from user-scope `settings.json` into a project `.claude/settings.local.json` (gitignored). Run during worktree setup so subagents inherit MCP permissions. Idempotent. |

## Plans and temporary files

Do not use the superpowers-default plans location (`~/.claude/plans/`). Each repo has its own location for plans and temporary files — typically a `temp/` directory at the repo root. Check the repo's CLAUDE.md for the specific path. If it doesn't exist, create `temp/` and put plans there.

## Git commands

Never use `cd <repo> && git <command>` to run git in a different directory — this triggers a permission prompt for the `cd`. Always use `git -C <path> <command>` instead. This applies everywhere: worktrees, other repos, any path that isn't the current working directory.

```bash
# Wrong — prompts for permission
cd /Users/steven/Archive/04_Projects/dimer-flutter && git diff main lib/foo.dart

# Right — pre-allowed, no prompt
git -C /Users/steven/Archive/04_Projects/dimer-flutter diff main lib/foo.dart
```

## Git worktrees

When starting feature work that needs git isolation, always use the `set-up-worktree` skill. Never use `superpowers:using-git-worktrees`.

## Plans and implementation

When writing and implementing plans, don't commit intermediate steps — just run /pre-commit at the end.

## PR description

Update the PR description to reflect current changes **before pushing code**, so that automated code reviewers have accurate context when they run. Use the `update-pr-description` skill.

## Git rules

- Always commit to a feature branch. Never commit directly to main.
- All commit messages must include the line `Written with Claude Code` to indicate Claude's involvement.
- **Use `~/.claude/scripts/git-commit.sh "<subject>" "[body]"` to commit** instead of a heredoc `git commit -m`. The script appends the required footer automatically and avoids shell-obfuscation permission prompts. Only fall back to raw `git commit` if the script is unavailable.
- All tests must pass, lint must be clean, and code must be formatted before committing. Run the formatter, linter, and test suite before every commit and fix any failures first.
- Before committing, remove unused code. Commented-out code must have an inline comment explaining why it is commented out but not deleted (e.g. a ticket number, a known reason it may be re-enabled). Commented-out code with no explanation is not allowed.
- **Never commit unless the user explicitly asks.** After finishing implementation, stop and wait. Do not commit as a final step of any flow unless told to.

## Subagents

- When dispatching implementer subagents via `superpowers:subagent-driven-development`, remove the commit step from every implementer prompt. Replace it with: **"Do NOT commit your work. Leave changes staged or unstaged. The human will commit after all tasks are complete."**
