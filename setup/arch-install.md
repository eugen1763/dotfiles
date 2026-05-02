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
```bash
fdisk /dev/nvme0n1   # or /dev/sda
```

**Recommended layout:**
| Partition | Size     | Type                        |
|-----------|----------|-----------------------------|
| /dev/sda1 | 1G       | EFI System (type 1)         |
| /dev/sda2 | Rest     | Linux root (type 20/23)     |

### Format Partitions
```bash
# EFI partition
mkfs.fat -F32 /dev/sda1

# LUKS encrypted root
cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptroot

# Btrfs on LUKS
mkfs.btrfs /dev/mapper/cryptroot
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
  btrfs-progs intel-ucode   # or amd-ucode
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
```
127.0.0.1   localhost
::1         localhost
127.0.1.1   myhostname.localdomain myhostname
```

### Initramfs (for LUKS encryption)
Edit `/etc/mkinitcpio.conf`:
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
```
Then:
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
```
default arch
timeout 3
console-mode keep
editor no
```

Create `/boot/loader/entries/arch.conf`:
```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options cryptdevice=UUID=<ROOT_UUID>:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw quiet
```

Get UUID with `blkid /dev/sda2`.

---

## 6. Network & Users

### Install Network Tools
```bash
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
