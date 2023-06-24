#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# echo "---" | tee -a /tmp/polybar.log
# polybar mybar 2>&1 | tee -a /tmp/polybar.log &
# disown

# echo "Bar launched..."

for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
  polybar-msg cmd quit
  MONITOR=$m polybar --reload mybar &
done
