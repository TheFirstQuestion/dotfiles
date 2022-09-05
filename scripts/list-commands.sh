printf '\nScripts:\n'
ls $DOTFILE_DIR/scripts

printf '\nFunctions:\n'

source $SOURCE_ALL_FUNCTIONS

# List source of every function sourced in this script
# Get only the line that has the name
# Trim off the ()
# Ignore functions that begin with _ (because they're helper functions)
typeset -f | grep ' ()' | grep -v '^_' | sed 's/ ()//'
