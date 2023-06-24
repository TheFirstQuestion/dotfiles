# Play a sound (helpful to chain after a long-running command)
notify() {
  # If no param passed, show default message
  local messageToSend=${1:-'That thing finished running!'}

  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    paplay "$HOME/dotfiles/assets/ding.wav"
    /usr/bin/notify-send "$messageToSend"
    # TODO: also log
    # TODO: adjust volume
  # Mac
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    afplay /System/Library/Sounds/Submarine.aiff -v 10
  fi

}
