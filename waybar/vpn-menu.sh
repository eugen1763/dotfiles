#!/usr/bin/env bash
# rofi picker for the WireGuard connections.
# Select an inactive connection to connect it, the active one to disconnect it.

mapfile -t names < <(nmcli -t -f NAME,TYPE connection show |
                     awk -F: '$2 == "wireguard" { print $1 }')

if [[ ${#names[@]} -eq 0 ]]; then
    notify-send -u critical "VPN" "No WireGuard connection configured"
    exit 1
fi

active=$(nmcli -t -f NAME,TYPE connection show --active |
         awk -F: '$2 == "wireguard" { print $1; exit }')

menu=""
for name in "${names[@]}"; do
    if [[ $name == "$active" ]]; then
        menu+="● $name"$'\n'
    else
        menu+="○ $name"$'\n'
    fi
done

choice=$(printf '%s' "$menu" | rofi -dmenu -p "VPN" -i)
[[ -z $choice ]] && exit 0

choice=${choice:2}
if [[ $choice == "$active" ]]; then
    nmcli connection down "$choice" >/dev/null &&
        notify-send "VPN" "$choice disconnected"
else
    [[ -n $active ]] && nmcli connection down "$active" >/dev/null
    if nmcli connection up "$choice" >/dev/null; then
        notify-send "VPN" "$choice connected"
    else
        notify-send -u critical "VPN" "$choice failed to connect"
    fi
fi

pkill -RTMIN+8 waybar
