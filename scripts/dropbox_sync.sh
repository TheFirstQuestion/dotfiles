#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Dependency: dbxcli-extras (https://github.com/shadiakiki1986/dbxcli-extras)

DROPBOX_DIR="$HOME/Dropbox"

# Loop through each subfolder
for folderPath in "$DROPBOX_DIR"/*/; do
  basename=$(basename "$folderPath")
  echo "/$basename..."
  dbxcli_extras sync "$folderPath" "$basename"
done

echo 'Done!'

return 0
