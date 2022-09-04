echo '\nScripts:'
ls $DOTFILE_DIR/scripts

echo '\nFunctions:'

# loop necessary bc source doesn't do wildcards
for thisFilePath in $DOTFILE_DIR/functions/*; do
  source "$thisFilePath"
done

# List all the functions sourced in this script
# Get only the line that has the name
# Trim off the ()
typeset -f | grep ' ()' | sed 's/ ()//'
