# Arch Linux Installation Guide

## 1. Pre-Installation

### Download ISO & Create Bootable USB
```bash
# Download from https://archlinux.org/download/
# Write to USB:
sudo dd bs=4M if=archlinux-*.iso of=/dev/sdX conv=fsync status=progress
```

### Boot from USB
- Disable Secure Boot in BIOS
- Boot into UEFI mode (not legacy/CSM)

### Verify Boot Mode
```bash
ls /sys/firmware/efi/efivars   # must exist for UEFI
```

### Set Keyboard Layout (optional)
```bash
loadkeys de-latin1   # or your layout
```

### Connect to Internet
```bash
# Ethernet (should auto-connect via dhcpcd)
ping archlinux.org

# Wi-Fi
iwctl
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect <SSID>
  exit
```

### Update System Clock
```bash
timedatectl set-ntp true
```

---

## 2. Partitioning

### View Disks
```bash
lsblk
```

### Partition with fdisk (UEFI + LUKS + Btrfs)

Open fdisk on your target disk:
```bash
fdisk /dev/nvme0n1   # or /dev/sda
```

**fdisk prompt reference:**
| Command | Action                                  |
|---------|-----------------------------------------|
| `m`     | Show help / all commands                |
| `p`     | Print current partition table           |
| `g`     | Create new GPT partition table          |
| `n`     | Create new partition                    |
| `t`     | Change partition type                   |
| `d`     | Delete partition                        |
| `w`     | Write changes to disk and exit          |
| `q`     | Quit without saving                     |

**Step-by-step (interactive):**
```
Command (m for help): g          # create fresh GPT table
Command (m for help): n          # EFI partition
Partition number (1-128, default 1): <Enter>
First sector (2048-..., default 2048): <Enter>
Last sector, +/-sectors or +/-size: +1G

Command (m for help): t          # set EFI type
Partition type or alias (type L to list): 1

Command (m for help): n          # root partition
Partition number (2-128, default 2): <Enter>
First sector: <Enter>
Last sector: <Enter>             # rest of disk

Command (m for help): w          # write and exit
```

**One-liner (non-interactive):**
```bash
echo -e "g\nn\n\n\n+1G\nt\n1\nn\n\n\n\nw" | fdisk /dev/sda
```

**Recommended layout:**
| Partition | Size     | Type                        |
|-----------|----------|-----------------------------|
| /dev/sda1 | 1G       | EFI System (type 1)         |
| /dev/sda2 | Rest     | Linux root (type 20/23)     |

### Format Partitions
```bash
# 1. EFI partition
mkfs.fat -F32 /dev/sda1

# 2. LUKS container
cryptsetup luksFormat --type luks2 /dev/sda2
cryptsetup open /dev/sda2 cryptroot

# 3. Filesystem inside LUKS (MANDATORY — without this the next section fails)
mkfs.btrfs -f /dev/mapper/cryptroot
```

### Create Btrfs Subvolumes
```bash
mount /dev/mapper/cryptroot /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
umount /mnt
```

### Mount Filesystems
```bash
mount -o compress=zstd,subvol=@ /dev/mapper/cryptroot /mnt
mkdir -p /mnt/{home,boot,.snapshots,var/log}
mount -o compress=zstd,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o compress=zstd,subvol=@snapshots /dev/mapper/cryptroot /mnt/.snapshots
mount -o compress=zstd,subvol=@var_log /dev/mapper/cryptroot /mnt/var/log
mount /dev/sda1 /mnt/boot
```

---

## 3. Base Installation

### Install Essential Packages
```bash
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  btrfs-progs intel-ucode archlinux-keyring  # or amd-ucode
```

### Generate fstab
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

---

## 4. Chroot & Configure

### Enter Chroot
```bash
arch-chroot /mnt
```

> **No text editor?** The base system only has `echo`/`cat` available by default.
> Install one: `pacman -S vim` (or `nano`), or use the `sed`/heredoc approaches below.

### Time & Locale
```bash
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=de-latin1" > /etc/vconsole.conf   # optional
```

### Hostname
```bash
echo "myhostname" > /etc/hostname
```

### /etc/hosts
```bash
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   myhostname.localdomain myhostname
EOF
```

### Initramfs (for LUKS encryption)
Replace the HOOKS line (no editor needed):
```bash
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
```
Then rebuild:
```bash
mkinitcpio -P
```

### Root Password
```bash
passwd
```

---

## 5. Bootloader (systemd-boot)

```bash
bootctl --path=/boot install
```

Create `/boot/loader/loader.conf`:
```bash
cat > /boot/loader/loader.conf << 'EOF'
default arch
timeout 3
console-mode keep
editor no
EOF
```

Create `/boot/loader/entries/arch.conf` (replace `<ROOT_UUID>` with your actual UUID):
```bash
ROOT_UUID=$(blkid -s UUID -o value /dev/sda2)
cat > /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=$ROOT_UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet
EOF
```

---

## 6. Network & Users

### Install Network Tools
```bash
# If you get "PGP signature" errors, fix the keyring first:
pacman-key --init && pacman-key --populate archlinux
pacman -Sy archlinux-keyring

pacman -S networkmanager
systemctl enable NetworkManager
```

### Create User
```bash
useradd -m -G wheel,users username
passwd username
EDITOR=nvim visudo   # uncomment %wheel ALL=(ALL) ALL
```

---

## 7. Finish & Reboot

```bash
exit                # leave chroot
umount -R /mnt
reboot
```

## 8. Post-Install (in new system)

### Install Yay (AUR helper)
```bash
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si
```

### Install packages from this repo
```bash
# Native packages
sudo pacman -S --needed - < packages-native.txt

# AUR packages
yay -S --needed - < packages-aur.txt
```

### Enable services (from this repo)
```bash
while read -r service; do sudo systemctl enable "$service"; done < services-system.txt
while read -r service; do systemctl --user enable "$service"; done < services-user.txt
```

### Run install script
```bash
./install.sh
```

---

## Quick Reference

| Step                      | Command                                    |
|---------------------------|--------------------------------------------|
| Verify UEFI               | `ls /sys/firmware/efi/efivars`             |
| Wi-Fi                     | `iwctl`                                    |
| Partition                 | `fdisk /dev/nvme0n1`                       |
| Pacstrap                  | `pacstrap -K /mnt base base-devel linux...`|
| Chroot                    | `arch-chroot /mnt`                         |
| Generate fstab            | `genfstab -U /mnt >> /mnt/etc/fstab`       |
| Install bootloader        | `bootctl --path=/boot install`             |
