# NixOS Installation Guide for `finns-clanker-station`

> **This guide assumes you have never installed NixOS before.** Every step is explained.

---

## Table of Contents

1. [What This Setup Will Give You](#what-this-setup-will-give-you)
2. [Before You Start](#before-you-start)
3. [Step 1: Create a Bootable USB](#step-1-create-a-bootable-usb)
4. [Step 2: Boot the NixOS Installer](#step-2-boot-the-nixos-installer)
5. [Step 3: Connect to WiFi](#step-3-connect-to-wifi)
6. [Step 4: Partition & Encrypt Your Disk](#step-4-partition--encrypt-your-disk)
7. [Step 5: Generate Hardware Config](#step-5-generate-hardware-config)
8. [Step 6: Clone Your Dotfiles](#step-6-clone-your-dotfiles)
9. [Step 7: Install NixOS](#step-7-install-nixos)
10. [Step 8: Reboot & First Login](#step-8-reboot--first-login)
11. [Step 9: Change Your Password](#step-9-change-your-password)
12. [Step 10: Post-Install Setup](#step-10-post-install-setup)
13. [How to Update Your System Later](#how-to-update-your-system-later)
14. [Troubleshooting](#troubleshooting)

---

## What This Setup Will Give You

- **NixOS 24.11** with the **Hyprland** compositor
- **LUKS full-disk encryption** (everything except `/boot` is encrypted)
- **Flakes + Home Manager** — one command rebuilds your entire system
- All your configs (`hyprland`, `waybar`, `nvim`, `fish`, `kitty`, etc.) from your dotfiles repo
- Bluetooth, WiFi, PipeWire audio, Docker, and printing — all pre-configured
- **Steam excluded** as requested

---

## Before You Start

- [ ] A USB stick (at least 8GB)
- [ ] Your laptop plugged into power
- [ ] Internet access (WiFi or Ethernet)
- [ ] Your GitHub dotfiles repo URL: `https://github.com/eugen1763/dotfiles.git`

---

## Step 1: Create a Bootable USB

On your Arch desktop (or any working computer):

```bash
# Download the NixOS Minimal ISO (no GUI, smaller, TUI-based WiFi setup)
curl -L -o nixos.iso \
  https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-24.11-x86_64-linux.iso

# Find your USB device (be careful! it's usually /dev/sdX or /dev/nvmeXn1)
lsblk

# Flash the ISO (replace /dev/sdX with your actual USB device!)
sudo dd if=nixos.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

> **WARNING:** Double-check the device path. `dd` will destroy all data on the target device.

---

## Step 2: Boot the NixOS Installer

1. Plug the USB into your laptop.
2. Power on and enter the boot menu (usually `F12`, `F10`, or `Esc`).
3. Select the USB drive and boot into **NixOS Installer**.
4. You will land at a TTY (text console) with a root shell.

---

## Step 3: Connect to WiFi

If you are using Ethernet, skip this step.

The minimal ISO has no GUI, so we use a TUI (text user interface) to connect to WiFi.

### Method A: `nmtui` (Recommended — easiest)

`nmtui` is a friendly menu-driven tool. Use arrow keys and Enter to navigate.

```bash
# Start the NetworkManager TUI
nmtui
```

1. Select **"Activate a connection"**
2. Highlight your WiFi network and press **Enter**
3. Enter your WiFi password when prompted
4. Press **Esc** to exit
5. Verify connection:
   ```bash
   ping -c 3 google.com
   ```

### Method B: `iwctl` (Minimal — faster)

`iwctl` is a lightweight command-line tool. Good if `nmtui` is not available.

```bash
# Enter the iwd interactive shell
iwctl

# List WiFi devices
[iwd]# device list

# Scan for networks (replace wlan0 with your actual device name)
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks

# Connect to your network (replace "MyNetwork" with your actual SSID)
[iwd]# station wlan0 connect "MyNetwork"

# Enter your WiFi password when prompted, then exit
[iwd]# quit

# Verify connection
ping -c 3 google.com
```

> **Tip:** If `nmtui` is not found, you can install it temporarily with:
> ```bash
> nix-shell -p networkmanager
> ```
> Then run `nmtui` again.

---

## Step 4: Partition & Encrypt Your Disk

Open a terminal and run the following commands. **Replace `/dev/nvme0n1` with your actual disk** (check with `lsblk`).

```bash
# Become root
sudo -i

# Identify your disk
lsblk

# Wipe any existing data on the target disk (DANGEROUS - triple check the device!)
wipefs -a /dev/nvme0n1

# Partition the disk
#   - Partition 1: 512MB EFI partition (type 1)
#   - Partition 2: Rest of the disk for LUKS-encrypted root
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart primary 1MiB 512MiB
parted /dev/nvme0n1 -- mkpart primary 512MiB 100%
parted /dev/nvme0n1 -- set 1 esp on

# Format the EFI partition
mkfs.fat -F 32 -n boot /dev/nvme0n1p1

# Set up LUKS encryption on the second partition
# You will be prompted to enter and confirm a passphrase.
cryptsetup luksFormat /dev/nvme0n1p2

# Open the encrypted container (name it "cryptroot")
cryptsetup open /dev/nvme0n1p2 cryptroot

# Format the encrypted container as ext4
mkfs.ext4 -L nixos /dev/mapper/cryptroot

# Mount the filesystems
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

**What this does:**
- Creates a small unencrypted `/boot` partition (required for the bootloader).
- Encrypts everything else with LUKS2.
- At boot, you will type your passphrase to unlock the disk.

---

## Step 5: Generate Hardware Config

NixOS needs to know about your specific hardware (disk UUIDs, kernel modules, etc.). This command auto-detects everything:

```bash
nixos-generate-config --root /mnt
```

This creates two files on the installer:
- `/mnt/etc/nixos/configuration.nix` (we will ignore this)
- `/mnt/etc/nixos/hardware-configuration.nix` (**we need this**)

Copy the hardware config to your dotfiles location:

```bash
mkdir -p /mnt/home/finn/.config/nixos/hosts/finns-clanker-station
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/home/finn/.config/nixos/hosts/finns-clanker-station/
```

---

## Step 6: Clone Your Dotfiles

```bash
# Install git in the live environment
nix-shell -p git

# Clone your dotfiles repo (which contains the NixOS config)
git clone https://github.com/eugen1763/dotfiles.git /mnt/home/finn/.config

# Set correct ownership
chown -R 1000:1000 /mnt/home/finn/.config
```

Your repo will be cloned to `/mnt/home/finn/.config/`. After reboot, this becomes `~/.config/`.

---

## Step 7: Install NixOS

Before installing, we need to tell NixOS about the LUKS encryption.

### 7a. Edit the hardware config to add LUKS

Open the generated hardware config and add the LUKS device:

```bash
nano /mnt/home/finn/.config/nixos/hosts/finns-clanker-station/hardware-configuration.nix
```

Find the line that starts with `fileSystems."/"` and look at the `device` value. It should point to `/dev/disk/by-uuid/...`. **Copy that UUID**.

Then add this block near the top (after the `imports` line):

```nix
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
    preLVM = true;
    allowDiscards = true;
  };
```

Replace `YOUR-UUID-HERE` with the actual UUID from the `fileSystems."/"` line.

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

### 7b. Run the installer

```bash
nixos-install --flake /mnt/home/finn/.config/nixos#finns-clanker-station
```

This will:
1. Download all necessary packages
2. Build your system
3. Install the bootloader
4. Set up your user

> **This will take a while** (15-60 minutes depending on your internet speed).

If the install succeeds, you will see:
```
Finished.
```

---

## Step 8: Reboot & First Login

```bash
# Unmount everything
umount -R /mnt

# Close the encrypted container
cryptsetup close cryptroot

# Reboot
reboot
```

1. Remove the USB stick when prompted.
2. The laptop will boot into systemd-boot.
3. You will see a prompt asking for your LUKS passphrase. Type it and press Enter.
4. The system will boot into a TTY (text console).

---

## Step 9: Change Your Password

The initial password is set to `finn`. **Change it immediately** for security:

```bash
passwd
```

Enter your new password twice.

---

## Step 10: Post-Install Setup

### 10a. First-time login

After changing the password, log in as `finn` with your new password.

### 10b. Enable flakes (if not already enabled)

Your config already enables flakes, but to make sure the `nix` command works with flakes:

```bash
# This should already be set, but verify:
cat /etc/nix/nix.conf | grep experimental
```

If you see `experimental-features = nix-command flakes`, you're good.

### 10c. Clone your dotfiles properly (if not already there)

If the clone in Step 6 worked, your dotfiles should already be at `~/.config/`.

Verify:
```bash
ls ~/.config/nixos/
```

You should see `flake.nix`, `hosts/`, `home/`, `INSTALL.md`.

If they are missing, clone now:
```bash
git clone https://github.com/eugen1763/dotfiles.git ~/.config
```

### 10d. Rebuild the system

Any time you change your config, run:

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station
```

The first rebuild after installation should be quick since everything is already installed.

### 10e. Start Hyprland

Since your `.bash_profile` auto-starts Hyprland on TTY1, you can either:
- Reboot and let it auto-start, or
- Run `Hyprland` manually from the TTY.

---

## How to Update Your System Later

### Update everything (system + packages)

```bash
# Update nixpkgs and rebuild
sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station --upgrade
```

### Edit your configs

- **System config:** `~/.config/nixos/hosts/finns-clanker-station/configuration.nix`
- **Home config:** `~/.config/nixos/home/finn.nix`
- **Dotfiles (.bashrc, .gitconfig):** `~/.config/nixos/home/dotfiles/`
- **Hyprland, Waybar, Nvim, Fish, Kitty, etc.:** `~/.config/hypr/`, `~/.config/waybar/`, etc. (already in place from git)

After any edit, rebuild:
```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station
```

### Clean up old generations (free disk space)

```bash
sudo nix-collect-garbage -d
```

---

## Troubleshooting

### "I forgot my LUKS passphrase"

There is no recovery. You must reinstall. Always keep backups.

### "WiFi doesn't work after install"

Some Intel WiFi cards need firmware that might not be included in the minimal ISO. If WiFi doesn't work after install, connect via Ethernet temporarily and run:

```bash
sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station
```

The `hardware.enableAllFirmware = true;` line in `configuration.nix` should pull in the needed firmware.

### "Hyprland doesn't start"

1. Check for errors: run `Hyprland` from the TTY and read the output.
2. Make sure your `~/.config/hypr/hyprland.conf` exists (it should be there from the git clone).
3. Verify the `exec start-hyprland` or `exec Hyprland` logic in your config.

### "A package I want is not available"

NixOS uses nixpkgs, not the Arch User Repository (AUR). Most common packages are available. If something is missing (like `elephant`, `walker`, or `hyprlauncher`), you have options:

1. **Search nixpkgs:** https://search.nixos.org/packages
2. **Use a different tool** (e.g., `fuzzel` instead of `walker` — already included in your config)
3. **Package it yourself** in the NixOS config (advanced)
4. **Install it imperatively** with a custom build or AppImage

### "I want to change the hostname"

Edit `~/.config/nixos/hosts/finns-clanker-station/configuration.nix`, change `networking.hostName`, and rebuild.

### "How do I add a new user"

Edit `configuration.nix`, add another `users.users.<name>` block, and rebuild.

---

## Quick Reference

| Task | Command |
|------|---------|
| Rebuild system | `sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station` |
| Update & rebuild | `sudo nixos-rebuild switch --flake ~/.config/nixos#finns-clanker-station --upgrade` |
| Garbage collect | `sudo nix-collect-garbage -d` |
| Search packages | `nix search nixpkgs <name>` or https://search.nixos.org |
| Enter a shell with a package | `nix-shell -p <package>` |
| Edit system config | `nvim ~/.config/nixos/hosts/finns-clanker-station/configuration.nix` |
| Edit home config | `nvim ~/.config/nixos/home/finn.nix` |
| View generations | `sudo nix-env -p /nix/var/nix/profiles/system --list-generations` |
| Rollback to previous generation | Select it in the systemd-boot menu at startup |

---

**Welcome to NixOS!** 🎉
