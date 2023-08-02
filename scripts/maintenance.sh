# Import custom functions
source $SOURCE_ALL_FUNCTIONS

echo 'Running maintenance script!'

echo
echo

outputDir="$HOME/Archive/.maintenance/$(timestamp)"
mkdir -p $outputDir

# Redirect output to both terminal and file
exec > >(tee "${outputDir}/00_script_output.txt") 2>&1

echo "Initializing Archive..."
run_script init-archive "$HOME/Archive/"

echo

echo "Removing .DS_Store..."
cd /
run_script rm-DS_Store

echo

echo "Running updates..."
run_script update

echo

echo "Removing old downloads..."
# Move old downloads to the trash (older than 30 days)
find "$HOME/Downloads" -type f -mtime +30 -exec trash-put {} \;

echo

echo 'Done!'
