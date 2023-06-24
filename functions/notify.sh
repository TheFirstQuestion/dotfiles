# Play a sound (helpful to chain after a long-running command)
notify() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    paplay "$HOME/dotfiles/assets/ding.wav"
    /usr/bin/notify-send 'That thing finished running!'
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    afplay /System/Library/Sounds/Submarine.aiff -v 10
  fi
}
