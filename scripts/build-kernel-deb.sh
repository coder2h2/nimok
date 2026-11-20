#!/usr/bin/env bash
# Nimok Linux is a Linux Distro for coding and gaming
# Copyright (C) 2026  Gideon Laurie
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set -euo pipefail

REPO_DIR="$PWD"
OUT_DIR="${1:-$REPO_DIR/built-kernel-debs}"
KERNEL_VER="7.3.5"
WORK="/tmp/nimok-kernel-build"

rm -rf "$WORK" "$OUT_DIR"
mkdir -p "$WORK" "$OUT_DIR"

echo "=== Cloning Linux v${KERNEL_VER} ==="
git clone --depth 1 --branch "v${KERNEL_VER}" https://kernel.org "$WORK/linux" || \
  git clone --depth 1 https://github.com "$WORK/linux"

cd "$WORK/linux"

echo "=== Applying Nimok patches ==="
for p in "$REPO_DIR"/patches/*.patch; do
  if [ -f "$p" ]; then
    echo "Applying $(basename "$p")..."
    patch -p1 --forward < "$p" || true
  fi
done

if [ -f "$REPO_DIR/configs/kernel-7.3.5-nimok.config" ]; then
  cp "$REPO_DIR/configs/kernel-7.3.5-nimok.config" .config
  make olddefconfig
else
  make defconfig
  scripts/config --set-str CONFIG_LOCALVERSION "-nimok" --enable CONFIG_PREEMPT --enable CONFIG_HZ_1000
  make olddefconfig
fi

echo "=== Compiling Kernel .deb Packages ==="
# Bump build revision using git commit count so apt always sees a newer version
REV=$(git -C "$REPO_DIR" rev-list --count HEAD)
make -j"$(nproc)" bindeb-pkg KDEB_PKGVERSION="7.3.5-nimok-${REV}"

cp "$WORK"/linux-image-*.deb "$OUT_DIR/"
cp "$WORK"/linux-headers-*.deb "$OUT_DIR/" 2>/dev/null || true
rm -rf "$WORK"

echo "=== Kernel .deb packages ready in $OUT_DIR ==="
