#!/bin/bash

# Function to check the status of the Caps Lock key
get_capslock_status() {
  caps_status=$(xset q | grep "Caps Lock:" | awk '{print $4}')
  if [ "$caps_status" = "on" ]; then
    echo -n "CAPS "
  fi
}

# Function to check the status of the Num Lock key
get_numlock_status() {
  num_status=$(xset q | grep "Num Lock:" | awk '{print $8}')
  if [ "$num_status" = "off" ]; then
    echo -n "No Num! "
  fi
}

# Get the combined lock status
combined_status=$(get_capslock_status)$(get_numlock_status)

# Print the combined status
echo "$combined_status"
