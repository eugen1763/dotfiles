#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Must run as regular user (makepkg requirement)
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run this script as root. Run as your regular user with sudo access." >&2
    exit 1
fi

# Check Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo "Error: This script is intended for Arch Linux only." >&2
    exit 1
fi

SUDO="sudo"

echo "==> Updating pacman database..."
$SUDO pacman -Sy

echo "==> Installing native packages..."
mapfile -t native_pkgs < <(grep -v '^#' "$SCRIPT_DIR/packages-native.txt" | grep -v '^$')
if ((${#native_pkgs[@]} > 0)); then
    $SUDO pacman -S --needed --noconfirm "${native_pkgs[@]}"
else
    echo "    No native packages to install."
fi

echo "==> Bootstrapping yay if needed..."
if ! command -v yay &> /dev/null; then
    echo "==> yay not found. Building yay-bin from AUR..."
    TMPDIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR/yay-bin"
    cd "$TMPDIR/yay-bin"
    makepkg -si --noconfirm
    cd "$SCRIPT_DIR"
    rm -rf "$TMPDIR"
fi

echo "==> Installing AUR packages..."
mapfile -t aur_pkgs < <(grep -v '^#' "$SCRIPT_DIR/packages-aur.txt" | grep -v '^$')
if ((${#aur_pkgs[@]} > 0)); then
    yay -S --needed --noconfirm "${aur_pkgs[@]}"
else
    echo "    No AUR packages to install."
fi

echo "==> Enabling system services..."
while IFS= read -r service; do
    [[ "$service" =~ ^#.*$ ]] && continue
    [[ -z "$service" ]] && continue
    echo "    -> $service"
    $SUDO systemctl enable "$service"
done < "$SCRIPT_DIR/services-system.txt"

echo "==> Enabling user services..."
while IFS= read -r service; do
    [[ "$service" =~ ^#.*$ ]] && continue
    [[ -z "$service" ]] && continue
    echo "    -> $service"
    # elephant ships no systemd unit; it is generated + enabled via its own
    # subcommand. A plain `systemctl --user enable elephant` fails here.
    if [[ "$service" == "elephant" ]]; then
        elephant service enable
        systemctl --user daemon-reload
        systemctl --user enable --now elephant.service
    else
        systemctl --user enable "$service"
    fi
done < "$SCRIPT_DIR/services-user.txt"

echo ""
echo "==> Setup complete!"
