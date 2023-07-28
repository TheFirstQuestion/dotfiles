# Import custom functions
source $SOURCE_ALL_FUNCTIONS

echo 'Running maintenance script!'

outputDir="$HOME/Archive/.maintenance/$(timestamp)"
mkdir -p $outputDir && cd $outputDir

echo "Initializing Archive..."
run_script init-archive "$HOME/Archive/"

echo "Removing .DS_Store..."
run_script rm-DS_Store

echo "Running updates..."
run_script update

# Looking at modification times (since epoch)
# for thisFilePath in "$HOME/Downloads/*"; do
#   stat -f "%m" $thisFilePath
# done

echo 'Done!'
