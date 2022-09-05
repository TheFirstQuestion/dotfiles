#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

diveIntoDir() {
  # Identify git repo
  if [[ $(git -C "$1" status 2>/dev/null) ]]; then
    # Skip (for now)
    return 0
  fi

  # Process the files in this directory
  processFiles "$1"

  # And recurse downwards
  for thisDirPath in $(find "$1" -type d -maxdepth 1 | sort); do
    nameOf1=$(basename $1)
    thisDir=$(basename $thisDirPath)

    # Compare to any ignored dirs
    # Also prevent infinite loop -- don't call on the current directory
    if [[ -n $(echo ".git node_modules compiled __pycache__ build .AppleDouble .npm .sass-cache .ipynb_checkpoints profile_default .AppleDB .AppleDesktop Network Trash Folder Temporary Items .apdisk $nameOf1" | grep "$thisDir") ]]; then
      continue
    fi

    diveIntoDir "$thisDirPath"
  done
}

processFiles() {
  for thisFilePath in $(find "$1" -type f -maxdepth 1 | sort); do
    # sed to escape square brackets (via https://superuser.com/a/1383431)
    thisFile=$(basename $thisFilePath | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g')

    # Compare to any ignored filenames
    if [[ -n $(echo ".DS_Store ipython_config.py local.properties google-services.json .DocumentRevisions-V100 .fseventsd .Spotlight-V100 .TemporaryItems .Trashes .VolumeIcon.icns .com.apple.timemachine.donotpresent" | grep "$thisFile") ]]; then
      continue
    fi

    echo "$thisFilePath"
  done
}

############################## EXECUTION BEGINS HERE #############################

# Start recursing
diveIntoDir "$HOME/Archive"

exit 0
