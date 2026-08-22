#!/usr/bin/env bash
set -euo pipefail

# Fixes the elephant user service that the original install.sh failed on,
# then upgrades the whole system (native + AUR).
#
# Run as your regular user (NOT root). It will prompt for your sudo password.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run this script as root. Run as your regular user with sudo access." >&2
    exit 1
fi

# Prime sudo up front (prompts for password) and keep it alive for the run.
echo "==> Requesting sudo access..."
sudo -v
# Refresh the sudo timestamp in the background until this script exits.
( while true; do sudo -n true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

# --- 1. Fix the missing elephant service --------------------------------
# The elephant package does NOT ship a systemd unit; it is generated and
# installed by `elephant service enable`. The original install.sh tried
# `systemctl --user enable elephant`, which fails with "Unit could not be
# found". This is the correct way to register + enable it.
echo "==> Registering and enabling elephant user service..."
if command -v elephant &>/dev/null; then
    elephant service enable
    systemctl --user daemon-reload
    systemctl --user enable --now elephant.service
    echo "    elephant service status:"
    systemctl --user --no-pager status elephant.service | head -5 || true
else
    echo "    Error: elephant binary not found; install the 'elephant' AUR package first." >&2
    exit 1
fi

# --- 2. Upgrade everything ----------------------------------------------
echo "==> Refreshing databases and upgrading native + AUR packages..."
if command -v yay &>/dev/null; then
    # yay -Syu upgrades both official and AUR packages in one pass.
    yay -Syu --noconfirm
else
    sudo pacman -Syu --noconfirm
fi

echo ""
echo "==> Done. Elephant service is enabled and the system is up to date."
