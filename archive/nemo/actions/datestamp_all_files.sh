#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Change to the directory (passed as the first argument)
cd "$1"
shift

# Loop through each filename (passed as an argument)
while [ $# -gt 0 ]; do
  # If item is "Untitled Folder", don't prepend, just rename
  if [ "$(basename $1)" == "Untitled Folder" ]; then
    mv "$1" "$(date +"%Y-%m-%d")"
  else
    mv "$1" "$(date +"%Y-%m-%d") -- $(basename $1)"
  fi
  shift
done
