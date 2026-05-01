#!/bin/bash
# Waybar custom media module using playerctl
playerctl -a metadata --format '{"text": "{{artist}} - {{title}}", "tooltip": "{{playerName}}: {{artist}} - {{album}} - {{title}}", "alt": "{{status}}", "class": "{{status}}"}' -F
