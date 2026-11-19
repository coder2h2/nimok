#!/usr/bin/env bash
# Nimok Linux is a Linux Distro for coding and gaming
# Copyright (C) 2026  Gideon Laurie
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set -euo pipefail

ARCH="${1:-amd64}"
REPO_DIR="$PWD"
WORKDIR="$REPO_DIR/work-$ARCH"
ROOTFS="$WORKDIR/rootfs"
ISO_DIR="$WORKDIR/iso"
OUT_ISO="$REPO_DIR/nimok-0.1-nifoun-${ARCH}.iso"

echo "=== Building Nimok Linux 0.1 (Nifoun) for $ARCH ==="
mkdir -p "$WORKDIR" "$ROOTFS" "$ISO_DIR/live" "$ISO_DIR/boot/grub"

# 1. Install host build dependencies
sudo apt-get update
sudo apt-get install -y \
  cpio squashfs-tools xorriso mtools \
  mmdebstrap debian-archive-keyring grub-common

# 2. Bootstrap Debian Sid rootfs using mmdebstrap's built-in mirrors
sudo mmdebstrap --arch="$ARCH" --variant=minbase \
  --aptopt='Acquire::AllowInsecureRepositories "true"' \
  --aptopt='APT::Get::AllowUnauthenticated "true"' \
  --include=debian-archive-keyring \
  testing "$ROOTFS"

sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /proc "$ROOTFS/proc"
sudo mount --bind /sys "$ROOTFS/sys"

sudo chroot "$ROOTFS" apt-get update
sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  systemd-sysv udev dbus network-manager sudo locales ca-certificates \
  pipewire pipewire-pulse wireplumber \
  plasma-desktop kwin-wayland sddm konsole dolphin kate \
  calamares parted dosfstools e2fsprogs btrfs-progs efibootmgr \
  squashfs-tools live-boot initramfs-tools \
  git curl build-essential python3 nodejs npm nano

# 3. Install kernel (pre-compiled from repo on amd64, via apt on arm64)
sudo mkdir -p "$ROOTFS/boot"
if [ "$ARCH" = "amd64" ]; then
  sudo apt-get install -y grub-pc-bin grub-efi-amd64-bin
  sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends grub-pc-bin grub-efi-amd64-bin
  sudo cp "$REPO_DIR/kernel/amd64/vmlinuz-7.3.5-nimok" "$ROOTFS/boot/vmlinuz-7.3.5-nimok"
  sudo tar -xf "$REPO_DIR/kernel/amd64/modules-7.3.5-nimok.tar.xz" -C "$ROOTFS/"
  K_VER="7.3.5-nimok"
else
  sudo apt-get install -y grub-efi-arm64-bin
  sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends grub-efi-arm64-bin linux-image-arm64
  K_VER=$(ls "$ROOTFS/lib/modules" | head -n 1)
fi

# 4. Apply Nimok 0.1 (Nifoun) branding, Calamares config, user, and SDDM auto-login
sudo mkdir -p "$ROOTFS/usr/share/pixmaps" "$ROOTFS/usr/share/icons/hicolor/256x256/apps" "$ROOTFS/etc/calamares" "$ROOTFS/etc/sddm.conf.d"
sudo cp "$REPO_DIR/assets/nimok-logo.png" "$ROOTFS/usr/share/pixmaps/nimok-logo.png"
sudo cp "$REPO_DIR/assets/nimok-logo.png" "$ROOTFS/usr/share/icons/hicolor/256x256/apps/nimok.png"
sudo cp -r "$REPO_DIR/calamares/"* "$ROOTFS/etc/calamares/"

sudo bash -c "cat << 'EOT' > '$ROOTFS/etc/os-release'
NAME=\"Nimok\"
VERSION=\"0.1 (Nifoun)\"
ID=nimok
ID_LIKE=debian
PRETTY_NAME=\"Nimok Linux 0.1 (Nifoun)\"
LOGO=nimok
HOME_URL=\"https://github.com\"
SUPPORT_URL=\"https://github.com/issues\"
BUG_REPORT_URL=\"https://github.com/issues\"
EOT"

echo "nimok" | sudo tee "$ROOTFS/etc/hostname"
sudo chroot "$ROOTFS" useradd -m -G sudo,video,audio,input -s /bin/bash nimok || true
echo "nimok:nimok" | sudo chroot "$ROOTFS" chpasswd
echo "nimok ALL=(ALL) NOPASSWD: ALL" | sudo tee "$ROOTFS/etc/sudoers.d/nimok"

sudo bash -c "cat << 'EOT' > '$ROOTFS/etc/sddm.conf.d/autologin.conf'
[Autologin]
User=nimok
Session=plasma
EOT"

sudo mkdir -p "$ROOTFS/home/nimok/Desktop"
sudo bash -c "cat << 'EOT' > '$ROOTFS/home/nimok/Desktop/install-nimok.desktop'
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Nimok Linux
GenericName=System Installer
Comment=Install Nimok Linux 0.1 (Nifoun) to disk
Exec=sudo calamares
Icon=/usr/share/pixmaps/nimok-logo.png
Terminal=false
Categories=System;
EOT"
sudo chmod +x "$ROOTFS/home/nimok/Desktop/install-nimok.desktop"
sudo chroot "$ROOTFS" chown -R nimok:nimok /home/nimok

# 5. Generate initramfs and pack bootable ISO
sudo mkdir -p "$ROOTFS/lib/udev"
sudo ln -sf /usr/lib/udev/*_id "$ROOTFS/lib/udev/" 2>/dev/null || true
sudo chroot "$ROOTFS" update-initramfs -c -k "$K_VER"
sudo umount "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys"

sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 15
sudo cp "$ROOTFS/boot/vmlinuz-${K_VER}" "$ISO_DIR/boot/vmlinuz"
sudo cp "$ROOTFS/boot/initrd.img-${K_VER}" "$ISO_DIR/boot/initrd.img"

cat << 'EOT' > "$ISO_DIR/boot/grub/grub.cfg"
set timeout=5
set default=0

menuentry "Nimok Linux 0.1 (Nifoun) - Live Desktop & Installer" {
    linux /boot/vmlinuz boot=live components quiet splash
    initrd /boot/initrd.img
}
EOT

grub-mkrescue -o "$OUT_ISO" "$ISO_DIR"
echo "=== Finished: $OUT_ISO ==="
