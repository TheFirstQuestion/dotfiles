# Import custom functions
source $SOURCE_ALL_FUNCTIONS

echo 'Running maintenance script!'

echo
echo

outputDir="$HOME/Archive/.maintenance/$(timestamp)"
mkdir -p $outputDir

# Redirect output to both terminal and file
exec > >(tee "${outputDir}/00_script_output.txt") 2>&1

# Initialize Archive
echo "Initializing Archive..."
run_script init-archive "$HOME/Archive/"

echo

# Remove .DS_Store files
echo "Removing .DS_Store..."
cd /
run_script rm-DS_Store

echo

# Move old downloads to the trash (older than 30 days)
echo "Removing old downloads..."
find "$HOME/Downloads" -type f -mtime +30 -exec trash-put {} \;

echo

# Sync Dropbox
echo "Synching Dropbox..."
run_script dropbox_sync

# Update Discord
echo "Updating Discord..."
run_script update_discord

echo 'Done!'
