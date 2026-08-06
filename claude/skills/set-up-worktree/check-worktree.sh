#!/usr/bin/env bash
# Probe the health of a worktree setup — all checks run in parallel.
# Usage: check-worktree.sh <repo-root> <worktree-path>
# Output: one line per check: <check>:(ok|missing|na)[=<detail>]

set -euo pipefail

# Auto-detect when called with no args (must be run from inside the worktree)
if [[ $# -eq 0 ]]; then
  WORKTREE_PATH="$PWD"
  REPO_ROOT=$(dirname "$(git rev-parse --git-common-dir)")
else
  REPO_ROOT="${1:?Usage: check-worktree.sh [<repo-root> <worktree-path>]}"
  WORKTREE_PATH="${2:?Usage: check-worktree.sh [<repo-root> <worktree-path>]}"
fi

# --- env files, .mcp.json, .claude/settings.local.json (copy-files.sh domain) ---
check_copy_files() {
  local missing=()
  while IFS= read -r -d '' file; do
    rel="${file#"$REPO_ROOT/"}"
    [[ ! -f "$WORKTREE_PATH/$rel" ]] && missing+=("$rel")
  done < <(find "$REPO_ROOT" -maxdepth 1 \( -name '.env*' -o -name 'env-*.json' \) -type f -print0 2>/dev/null)
  [[ -f "$REPO_ROOT/.claude/settings.local.json" && ! -f "$WORKTREE_PATH/.claude/settings.local.json" ]] \
    && missing+=(".claude/settings.local.json")
  [[ -f "$REPO_ROOT/.mcp.json" && ! -f "$WORKTREE_PATH/.mcp.json" ]] \
    && missing+=(".mcp.json")
  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "copy_files:ok"
  else
    echo "copy_files:missing=$(IFS=,; echo "${missing[*]}")"
  fi
}

# --- code-review-graph ---
check_crg() {
  if [[ ! -d "$REPO_ROOT/.code-review-graph" ]]; then
    echo "crg:na"
  elif [[ -f "$WORKTREE_PATH/.code-review-graph/graph.db" ]]; then
    echo "crg:ok"
  else
    echo "crg:missing"
  fi
}

# --- git upstream tracking ---
check_upstream() {
  if git -C "$WORKTREE_PATH" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    echo "upstream:ok"
  else
    echo "upstream:missing"
  fi
}

# --- git hooks (for repos without dev_setup.sh) ---
check_hooks() {
  if [[ ! -f "$WORKTREE_PATH/tools/hooks/install.sh" ]]; then
    echo "hooks:na"
  elif git -C "$WORKTREE_PATH" config core.hooksPath >/dev/null 2>&1; then
    echo "hooks:ok"
  else
    echo "hooks:missing"
  fi
}

# --- iOS SPM ---
check_ios_spm() {
  local workspace
  workspace=$(find "$WORKTREE_PATH/ios" -maxdepth 1 -name "*.xcworkspace" -type d 2>/dev/null | head -1)
  if [[ -z "$workspace" ]]; then
    echo "ios_spm:na"
    return
  fi
  local workspace_name
  workspace_name=$(basename "$workspace" .xcworkspace)
  local derived
  derived=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name "${workspace_name}-*" -type d 2>/dev/null | head -1)
  if [[ -n "$derived" && -d "$derived/SourcePackages" ]]; then
    echo "ios_spm:ok"
  else
    echo "ios_spm:missing"
  fi
}

check_copy_files &
check_crg &
check_upstream &
check_hooks &
check_ios_spm &
wait
