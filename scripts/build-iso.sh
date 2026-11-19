#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-amd64}"
KERNEL_VER="7.3.5"
WORKDIR="$PWD/work-$ARCH"
ROOTFS="$WORKDIR/rootfs"
ISO_DIR="$WORKDIR/iso"
OUT_ISO="$PWD/nimok-0.1-nifoun-${ARCH}.iso"

echo "=== Building Nimok Linux 0.1 (Nifoun) for $ARCH ==="
mkdir -p "$WORKDIR" "$ROOTFS" "$ISO_DIR/live" "$ISO_DIR/boot/grub"

# 1. Install host build dependencies
sudo apt-get update
sudo apt-get install -y \
  build-essential bc bison flex libssl-dev libelf-dev dwarves \
  wget xz-utils cpio squashfs-tools xorriso mtools \
  mmdebstrap qemu-user-static grub-common

if [ "$ARCH" = "amd64" ]; then
  sudo apt-get install -y grub-pc-bin grub-efi-amd64-bin
  K_ARCH="x86_64"
  K_IMAGE="arch/x86/boot/bzImage"
else
  sudo apt-get install -y grub-efi-arm64-bin
  K_ARCH="arm64"
  K_IMAGE="arch/arm64/boot/Image"
fi

# 2. Download, patch, and compile Linux 7.3.5-nimok kernel
cd "$WORKDIR"
wget -q "https://kernel.org{KERNEL_VER}.tar.xz"
tar -xf "linux-${KERNEL_VER}.tar.xz"
cd "linux-${KERNEL_VER}"

for p in "$OLDPWD"/patches/*.patch; do
  [ -f "$p" ] && patch -p1 --forward < "$p" || true
done

if [ "$ARCH" = "amd64" ] && [ -f "$OLDPWD/configs/kernel-7.3.5-nimok.config" ]; then
  cp "$OLDPWD/configs/kernel-7.3.5-nimok.config" .config
  make ARCH="$K_ARCH" olddefconfig
else
  make ARCH="$K_ARCH" defconfig
  scripts/config --set-str CONFIG_LOCALVERSION "-nimok" \
    --enable CONFIG_PREEMPT \
    --enable CONFIG_HZ_1000 \
    --enable CONFIG_DRM \
    --enable CONFIG_DRM_VIRTIO_GPU \
    --enable CONFIG_DRM_FBDEV_EMULATION \
    --enable CONFIG_INPUT_EVDEV \
    --enable CONFIG_SQUASHFS \
    --enable CONFIG_SQUASHFS_XZ \
    --enable CONFIG_SQUASHFS_ZSTD \
    --enable CONFIG_OVERLAY_FS \
    --enable CONFIG_EXT4_FS \
    --enable CONFIG_BTRFS_FS \
    --enable CONFIG_VFAT_FS \
    --enable CONFIG_BLK_DEV_LOOP \
    --enable CONFIG_ISO9660_FS
  make ARCH="$K_ARCH" olddefconfig
fi

make ARCH="$K_ARCH" -j"$(nproc)"
sudo mkdir -p "$ROOTFS/boot"
sudo cp "$K_IMAGE" "$ROOTFS/boot/vmlinuz-${KERNEL_VER}-nimok"
sudo make ARCH="$K_ARCH" INSTALL_MOD_PATH="$ROOTFS" modules_install

# 3. Bootstrap Debian Sid rootfs with KDE Plasma, Calamares, and Coding tools
sudo mmdebstrap --arch="$ARCH" --variant=minbase sid "$ROOTFS" http://debian.org

sudo mount --bind /dev "$ROOTFS/dev"
sudo mount --bind /proc "$ROOTFS/proc"
sudo mount --bind /sys "$ROOTFS/sys"

sudo chroot "$ROOTFS" apt-get update
sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
  systemd-sysv udev dbus network-manager sudo locales \
  pipewire pipewire-pulse wireplumber \
  plasma-desktop kwin-wayland sddm konsole dolphin kate \
  calamares parted dosfstools e2fsprogs btrfs-progs efibootmgr \
  squashfs-tools live-boot initramfs-tools \
  git curl ca-certificates build-essential python3 nodejs npm nano

if [ "$ARCH" = "amd64" ]; then
  sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y grub-pc-bin grub-efi-amd64-bin
else
  sudo chroot "$ROOTFS" env DEBIAN_FRONTEND=noninteractive apt-get install -y grub-efi-arm64-bin
fi

# 4. Apply Nimok 0.1 (Nifoun) branding, logo, user, and SDDM auto-login
sudo mkdir -p "$ROOTFS/usr/share/pixmaps" "$ROOTFS/usr/share/icons/hicolor/256x256/apps" "$ROOTFS/etc/calamares/branding/nimok" "$ROOTFS/etc/sddm.conf.d"
sudo cp "$OLDPWD/assets/nimok-logo.png" "$ROOTFS/usr/share/pixmaps/nimok-logo.png"
sudo cp "$OLDPWD/assets/nimok-logo.png" "$ROOTFS/usr/share/icons/hicolor/256x256/apps/nimok.png"
sudo cp "$OLDPWD/assets/nimok-logo.png" "$ROOTFS/etc/calamares/branding/nimok/nimok-logo.png"

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
sudo chroot "$ROOTFS" update-initramfs -c -k "${KERNEL_VER}-nimok"
sudo umount "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys"

sudo mksquashfs "$ROOTFS" "$ISO_DIR/live/filesystem.squashfs" -comp zstd -Xcompression-level 15
sudo cp "$ROOTFS/boot/vmlinuz-${KERNEL_VER}-nimok" "$ISO_DIR/boot/vmlinuz"
sudo cp "$ROOTFS/boot/initrd.img-${KERNEL_VER}-nimok" "$ISO_DIR/boot/initrd.img"

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
