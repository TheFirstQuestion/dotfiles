# Remove .DS_Store files recursively in a directory, default .
# (via https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/macos/macos.plugin.zsh)
rm_DS_Store() {
  find "${@:-.}" -type f -name .DS_Store -delete
  find "${@:-.}" -type d -name __MACOSX -delete
}
