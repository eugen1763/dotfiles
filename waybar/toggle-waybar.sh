#!/usr/bin/env bash

# Check if autohide is running
if pgrep -f autohide.sh >/dev/null; then
    pkill -9 -f autohide.sh
    echo "Waybar auto-hide disabled"
else
    "$HOME/.config/waybar/autohide.sh" >/dev/null 2>&1 &
    disown
    echo "Waybar auto-hide enabled"
fi