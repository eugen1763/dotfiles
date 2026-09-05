#!/usr/bin/env bash
# Connect or disconnect the WireGuard VPN, then refresh the waybar module.
# With an argument, connect that connection instead of the first one.

active=$(nmcli -t -f NAME,TYPE connection show --active |
         awk -F: '$2 == "wireguard" { print $1; exit }')

if [[ -n $active ]]; then
    nmcli connection down "$active" >/dev/null &&
        notify-send "VPN" "$active disconnected"
else
    target=${1:-$(nmcli -t -f NAME,TYPE connection show |
                  awk -F: '$2 == "wireguard" { print $1; exit }')}
    if [[ -z $target ]]; then
        notify-send -u critical "VPN" "No WireGuard connection configured"
        exit 1
    fi
    if nmcli connection up "$target" >/dev/null; then
        notify-send "VPN" "$target connected"
    else
        notify-send -u critical "VPN" "$target failed to connect"
    fi
fi

# custom/vpn listens on signal 8 (SIGRTMIN+8)
pkill -RTMIN+8 waybar
