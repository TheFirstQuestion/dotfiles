# (loop necessary bc source doesn't do wildcards)

for thisFilePath in $DOTFILE_DIR/functions/*; do
  fname=$(basename $thisFilePath)
  # Don't source this file, because infinite loop
  if [[ "$fname" == "source-all-functions.sh" ]]; then
    continue
  else
    source $thisFilePath
  fi
done
