#!/usr/bin/env bash
# Waybar custom/vpn module: state of the WireGuard connections in NetworkManager.
# "alt" selects the icon in modules.jsonc, "class" selects the colour in style.css.

name=$(nmcli -t -f NAME,TYPE connection show --active |
       awk -F: '$2 == "wireguard" { print $1; exit }')

if [[ -z $name ]]; then
    printf '{"text": "off", "tooltip": "No VPN connected", "alt": "down", "class": "down"}\n'
    exit 0
fi

addr=$(nmcli -t -f IP4.ADDRESS connection show "$name" | head -n1 | cut -d: -f2)
printf '{"text": "%s", "tooltip": "WireGuard: %s\\n%s", "alt": "up", "class": "up"}\n' \
    "$name" "$name" "${addr:-no address}"
