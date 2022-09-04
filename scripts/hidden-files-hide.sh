# Show/hide hidden files in Finder
# (adapted from https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/macos/macos.plugin.zsh)
defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder
