#!/usr/bin/env bash
# hyprlock reads the wl_seat capabilities once, when it binds the seat. While
# this session's VT is inactive libseat disables the seat and Hyprland then
# advertises a seat with no input devices, so hyprlock ends up with no
# wl_keyboard and never regains one. The lock screen still draws, but it
# accepts no keys and the session cannot be unlocked.
#
# Restart hyprlock every time this VT becomes active again, once the seat has
# real keyboards back. hyprlock 0.9.6 / hyprland 0.56.2.
set -u

vt="tty${XDG_VTNR:?}"
signature="${HYPRLAND_INSTANCE_SIGNATURE:?}"
active_vt=/sys/class/tty/tty0/active

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/hyprlock-vt-guard.${signature}.lock"
flock -n 9 || exit 0

keyboard_count() {
    hyprctl devices 2>/dev/null | grep -c 'Keyboard at'
}

# The machine runs a second Hyprland on another VT with its own hyprlock.
# Only ever touch the one belonging to this instance.
our_hyprlock() {
    local pid
    for pid in $(pgrep -x hyprlock); do
        if grep -qzFx "HYPRLAND_INSTANCE_SIGNATURE=$signature" "/proc/$pid/environ" 2>/dev/null; then
            echo "$pid"
            return 0
        fi
    done
    return 1
}

read -r previous < "$active_vt" || previous=""

while :; do
    sleep 1
    read -r current < "$active_vt" 2>/dev/null || continue
    [ "$current" = "$previous" ] && continue
    previous=$current

    [ "$current" = "$vt" ] || continue
    pid=$(our_hyprlock) || continue

    # Killing the lock client is only recoverable when Hyprland accepts a
    # replacement. Never strand the session if that option got lost.
    hyprctl getoption misc:allow_session_lock_restore 2>/dev/null \
        | grep -q 'bool: true' || continue

    # Wait for libseat to hand the input devices back, otherwise the
    # replacement comes up just as deaf as the client it replaces.
    for _ in $(seq 20); do
        [ "$(keyboard_count)" -gt 0 ] && break
        sleep 0.5
    done
    [ "$(keyboard_count)" -gt 0 ] || continue

    kill -9 "$pid" 2>/dev/null
    while kill -0 "$pid" 2>/dev/null; do sleep 0.1; done
    setsid hyprlock >/dev/null 2>&1 &
done
