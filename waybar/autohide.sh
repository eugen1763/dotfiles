#!/usr/bin/env bash
set -euo pipefail

# Hide when cursor is near the bar (top edge).
# Show again when cursor moves away (lower on the screen).
HIDE_Y=70     # within 70px of the top => hide
SHOW_Y=160    # below 160px => show again
SLEEP_SEC=0.05
pkill -USR1 waybar 2>/dev/null || true
hidden=1  # start visible

while true; do
  # Wait until waybar exists
  if ! pgrep -x waybar >/dev/null 2>&1; then
    sleep 0.2
    continue
  fi

  # hyprctl cursorpos output looks like: "123, 45"
  pos="$(hyprctl cursorpos 2>/dev/null || true)"
  y="$(printf '%s' "$pos" | awk -F', ' '{print $2}' | tr -d '\r')"

  # If hyprctl failed, don't spam toggles
  if [[ -z "${y:-}" ]]; then
    sleep 0.2
    continue
  fi

  # Hide when close to the bar
  if (( y <= HIDE_Y )) && (( hidden == 1 )); then
    pkill -USR1 waybar 2>/dev/null || true
    hidden=0

  # Show when far enough away
  elif (( y >= SHOW_Y )) && (( hidden == 0 )); then
    pkill -USR1 waybar 2>/dev/null || true
    hidden=1
  fi

  sleep "$SLEEP_SEC"
done
