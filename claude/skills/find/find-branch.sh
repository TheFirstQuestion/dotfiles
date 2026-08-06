#!/usr/bin/env bash
# find-branch.sh [--cwd <path>] <slug>
# Searches all repos under ~/Archive/04_Projects/ for a branch or worktree
# matching the given slug (case-insensitive ticket slug or PR number).
#
# Output format (one result per line, tab-separated):
#   worktree  <repo-path>  <branch>  <worktree-path>   [current]
#   branch    <repo-path>  <branch>                    [current]
#
# "current" is appended when the repo matches --cwd (used by the find skill
# to auto-select without prompting when the user is already in that repo).

CWD="$PWD"
if [[ "$1" == "--cwd" ]]; then
  CWD="$2"
  shift 2
fi

SLUG="${1:?Usage: find-branch.sh [--cwd <path>] <slug>}"
SLUG_LOWER=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]')
PROJECTS_DIR="$HOME/Archive/04_Projects"

# Resolve CWD to its repo root (handles being inside a worktree)
CWD_REPO=""
if [[ -n "$CWD" ]]; then
  CWD_REPO=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null || true)
  # If inside a linked worktree, the common dir points back to the main repo
  GIT_COMMON=$(git -C "$CWD" rev-parse --git-common-dir 2>/dev/null || true)
  if [[ -n "$GIT_COMMON" && "$GIT_COMMON" != ".git" ]]; then
    CWD_REPO=$(dirname "$GIT_COMMON")
  fi
fi

for repo in "$PROJECTS_DIR"/*/; do
  [[ -d "$repo/.git" ]] || continue
  repo_path="${repo%/}"

  # Determine if this repo matches the caller's cwd
  current_flag=""
  if [[ -n "$CWD_REPO" && "$repo_path" == "$CWD_REPO" ]]; then
    current_flag="current"
  fi

  # Check all worktrees for this repo
  while IFS= read -r line; do
    if [[ "$line" == worktree\ * ]]; then
      current_worktree="${line#worktree }"
    elif [[ "$line" == branch\ * ]]; then
      branch_ref="${line#branch }"
      branch="${branch_ref#refs/heads/}"
      branch_lower=$(echo "$branch" | tr '[:upper:]' '[:lower:]')
      if [[ "$branch_lower" == *"$SLUG_LOWER"* ]]; then
        if [[ "$current_worktree" == "$repo_path" ]]; then
          echo -e "branch\t$repo_path\t$branch\t\t$current_flag"
        else
          echo -e "worktree\t$repo_path\t$branch\t$current_worktree\t$current_flag"
        fi
      fi
    fi
  done < <(git -C "$repo" worktree list --porcelain 2>/dev/null)

  # Also check remote branches not yet checked out as worktrees
  while IFS= read -r remote_branch; do
    branch=$(echo "$remote_branch" | sed 's|^[[:space:]]*origin/||')
    branch_lower=$(echo "$branch" | tr '[:upper:]' '[:lower:]')
    if [[ "$branch_lower" == *"$SLUG_LOWER"* ]]; then
      already_found=$(git -C "$repo" worktree list --porcelain 2>/dev/null \
        | grep "^branch refs/heads/$branch$")
      if [[ -z "$already_found" ]]; then
        echo -e "branch\t$repo_path\t$branch\t\t$current_flag"
      fi
    fi
  done < <(git -C "$repo" branch -r 2>/dev/null | grep -v ' -> ')
done
