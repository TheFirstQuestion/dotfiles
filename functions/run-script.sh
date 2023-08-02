# TODO: on dotbot, make sure all scripts are executable

# General function for running one of my scripts
# Parameter: the name of the script in dotfiles/scripts/ (without the .sh)
run_script() {
  # pass along all the arguments except for $0 ("run-script") and $1 (name of the script)
  log "$1 script started..."
  chmod +x "$DOTFILE_DIR/scripts/$1.sh"
  "$DOTFILE_DIR/scripts/$1.sh" "${@:2}" && log "$1 script finished successfully" || log "$1 script FAILED"
}

# this is a custom function that provides matches for the bash autocompletion
# adapted from https://stackoverflow.com/a/39705866
_scripts_autocomplete() {
  # Special case: if nothing has been typed, we want to list everything
  if [[ -z "$2" ]]; then
    prefix=""
  elif [[ -n "$string" ]]; then
    prefix="$2"
  fi

  local file
  # iterate all files that start with our search string
  for file in $DOTFILE_DIR/scripts/*"$prefix"*; do
    # If the glob doesn't match, we'll get the glob itself, so make sure we have an existing file. This check also skips entries that are not a file.
    [[ -f $file ]] || continue
    # add the file (without the path prefix and without extension) to the list of autocomplete suggestions
    COMPREPLY+=($(basename "${file}" .sh))
  done
}

# Call our custom function to tab-complete when typing run_script, only if the script is running in an interactive shell (not being sourced init-env-vars)
if [[ -z "$SCRIPT_SOURCED" ]]; then
  complete -F _scripts_autocomplete run_script
fi
