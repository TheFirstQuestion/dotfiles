# cd into a path (e.g. a worktree) and start a fresh `claude` session there
# so it gets correct MCP discovery for that directory.
claude-at() {
  if [ -z "$1" ]; then
    echo "Usage: claude-at <path>"
    return 1
  fi
  cd "$1" && claude
}
