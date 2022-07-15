##!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# TODO: write logic around this
DESTINATION="/Volumes/DriveB"


diveIntoDir() {
    # Identify git repo
    if [[ $(git -C "$1" status 2>/dev/null) ]]; then
        # Skip (for now)
        return 0
    fi

    # Process the files in this directory
    processFiles "$1"

    # And recurse downwards
    for thisDirPath in $(find "$1" -type d -maxdepth 1)
    do
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
    # for thisFilePath in $(find "$1" -type f -maxdepth 1)
    # do
    #     # sed to escape square brackets (via https://superuser.com/a/1383431)
    #     thisFile=$(basename $thisFilePath | sed -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    #
    #     # Compare to any ignored filenames
    #     if [[ -n $(echo ".DS_Store ipython_config.py local.properties google-services.json .DocumentRevisions-V100 .fseventsd .Spotlight-V100 .TemporaryItems .Trashes .VolumeIcon.icns .com.apple.timemachine.donotpresent" | grep "$thisFile") ]]; then
    #         continue
    #     fi
    #
    #     rsync -hmPCa --dry-run "$thisFilePath"
    # done
    rsync -vhmPCa --dry-run --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" "$1" "$DESTINATION"
}


############################## EXECUTION BEGINS HERE #############################

# Confirm that DESTINATION exists and is valid
if [ ! -d "$DESTINATION" ]; then
    echo 'error: Destination not found'
    exit 1
fi

# Confirm that Archive exists and is a valid directory
if [ ! -d "$HOME/Archive" ]; then
    echo 'error: ~/Archive not found'
    exit 1
fi

# Log that we are starting, because it may take a while
sh "$DOTFILE_DIR/scripts/keybase-log.sh" "beginning backup to $DESTINATION"

# Call init-archive script on Archive and Destination, to ensure we have the right directories
sh "$DOTFILE_DIR/scripts/init-archive.sh" "$HOME/Archive"
sh "$DOTFILE_DIR/scripts/init-archive.sh" "$DESTINATION"
echo

# Start recursing
# diveIntoDir "$HOME/Archive"
rsync -vhmPCa --exclude-from="$DOTFILE_DIR/templates/gitignore" --exclude=".git/*" --exclude=".expo/*" "$HOME/Archive" "$DESTINATION"
# TODO: this puts an Archive folder on root of drive, want it to just put top-level folders



# Print out size information
echo "\n\nStorage:"
echo
df -H "$HOME/Archive/" "$DESTINATION"
echo
du -hsc $HOME/Archive/* | sort -hr | head -n 10
