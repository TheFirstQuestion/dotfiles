# Parameter: the name of the file in dotfiles/templates/
template() {
  cp $DOTFILE_DIR/templates/$1 ./$1
  # Rename as appropriate
  if [ $1 = "gitignore" ]; then
    mv gitignore .gitignore
  elif [ $1 = "README" ]; then
    mv README README.md
  elif [ $1 = "env" ]; then
    mv env .env.local
  elif [ $1 = "zshrc.local" ]; then
    mv zshrc.local ~/.zshrc.local
  fi
}
