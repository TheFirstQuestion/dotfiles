#!/bin/bash

# CONFIGURATION ##############################################################

# Brightness will be lowered to this value.
min_brightness=0

# Time to sleep (in seconds) between increments when fading.
fade_step_time=0.01

###############################################################################

get_brightness() {
  light -G | cut -d '.' -f 1
}

set_brightness() {
  light -S "$1"
}

fade_brightness() {
  local current_brightness
  current_brightness=$(get_brightness)

  if ((current_brightness > min_brightness)); then
    for ((level = current_brightness; level >= min_brightness; level--)); do
      set_brightness "$level"
      sleep $fade_step_time
    done
  fi
}

trap 'exit 0' TERM INT
trap "set_brightness $(get_brightness); kill %%" EXIT
fade_brightness
sleep 2147483647 &
wait
