#!/bin/bash
while true; do
    if playerctl status 2>/dev/null | grep -q "Playing"; then
        # Block suspend while media is playing
        systemd-inhibit --what=idle --why="Media playing" sleep 10 &
    fi
    sleep 10
done
