# Import custom functions
source $SOURCE_ALL_FUNCTIONS

echo 'Running maintenance script!'

now=$(date +%s)

outputDir="$HOME/Archive/.maintenance/$now"
mkdir -p $outputDir && cd $outputDir

run_script list-every-file | tee "archive_contents.txt"

# echo "Initializing Archive..."
# run_script init-archive

# echo "Removing .DS_Store..."
# run_script rm-DS_Store

# echo "Running updates..."
# run_script update

# Looking at modification times (since epoch)
# for thisFilePath in "$HOME/Downloads/*"; do
#   stat -f "%m" $thisFilePath
# done

echo 'Done!'
