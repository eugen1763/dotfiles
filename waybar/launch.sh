#!/usr/bin/env bash

# Terminate already running bar instances
killall -q waybar

# Stop old autohide loop if it's running
pkill -f "$HOME/.config/waybar/autohide.sh" 2>/dev/null || true

# Launch Waybar and log output
waybar 2>&1 | tee -a /tmp/waybar.log &
disown

# Launch autohide helper
"$HOME/.config/waybar/autohide.sh" >/dev/null 2>&1 &
disown

echo "Bars launched..."
