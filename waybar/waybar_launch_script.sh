#!/usr/bin/env bash

# Terminate already running bar instances
killall -q waybar

# Use a locale that is usually present even on minimal systems
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Launch Waybar and log output
waybar 2>&1 | tee -a /tmp/waybar.log &
disown

echo "Bars launched..."
