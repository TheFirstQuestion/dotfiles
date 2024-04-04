#!/bin/bash

# Map monitors to colors
declare -A monitor_colors

# Add key-value pairs to the dictionary
monitor_colors['eDP-1']='#0f0'
monitor_colors['HDMI-1']='#f00'
monitor_colors['DP-1']='#00f'

# Read the value of MONITOR environment variable, or default to 'eDP-1'
monitor=${MONITOR:-'eDP-1'}

notify-send "Monitor: $monitor"

# Output the color
echo ${monitor_colors[$monitor]}
