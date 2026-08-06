#!/usr/bin/env bash
# Copy gitignored-but-needed files from the main worktree into a new worktree.
# Usage: copy-files.sh <src-repo-root> <dest-worktree-path>

set -euo pipefail

SRC="$1"
DEST="$2"

copy_if_missing() {
  local src_file="$1"
  local dest_file="$2"
  if [[ ! -f "$src_file" ]]; then
    return
  fi
  if [[ -f "$dest_file" ]]; then
    echo "skipped (already exists): $dest_file"
  else
    mkdir -p "$(dirname "$dest_file")"
    cp "$src_file" "$dest_file"
    echo "copied: $dest_file"
  fi
}

# .env* and env-*.json at repo root
while IFS= read -r -d '' file; do
  rel="${file#"$SRC/"}"
  copy_if_missing "$file" "$DEST/$rel"
done < <(find "$SRC" -maxdepth 1 \( -name '.env*' -o -name 'env-*.json' \) -type f -print0)

# Local Claude settings
copy_if_missing "$SRC/.claude/settings.local.json" "$DEST/.claude/settings.local.json"

# Rewrite .mcp.json with --repo pointing at the worktree so CRG uses the
# worktree's graph.db instead of the main repo's (CRG serve auto-detects cwd,
# not the worktree path, which causes it to load the wrong graph).
if [[ -f "$SRC/.mcp.json" ]]; then
  python3 - "$SRC/.mcp.json" "$DEST/.mcp.json" "$DEST" <<'PYEOF'
import json, sys
src_path, dest_path, worktree = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src_path) as f:
    config = json.load(f)
for server in config.get("mcpServers", {}).values():
    if "code-review-graph" in (server.get("command", "") + " ".join(server.get("args", []))):
        args = server.get("args", [])
        if "--repo" not in args:
            args.extend(["--repo", worktree])
            server["args"] = args
with open(dest_path, "w") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
print(f"written: {dest_path}")
PYEOF
  # Prevent the machine-specific --repo path from ever being committed
  git -C "$DEST" update-index --skip-worktree .mcp.json 2>/dev/null || true
fi
