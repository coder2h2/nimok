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
OUT_DIR="${1:-$REPO_DIR/built-debs}"
rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

for pkg_dir in "$REPO_DIR"/packages/*/; do
  [ -f "$pkg_dir/pkg.conf" ] || continue
  unset PKG_NAME PKG_VERSION PKG_ARCH PKG_DEPENDS PKG_DESC
  source "$pkg_dir/pkg.conf"

  STAGE="/tmp/nimok-deb-${PKG_NAME}"
  rm -rf "$STAGE"
  mkdir -p "$STAGE/DEBIAN"

  if [ -d "$pkg_dir/files" ]; then
    cp -a "$pkg_dir/files/." "$STAGE/"
  fi

  cat << EOT > "$STAGE/DEBIAN/control"
Package: ${PKG_NAME}
Version: ${PKG_VERSION}
Section: misc
Priority: optional
Architecture: ${PKG_ARCH}
Depends: ${PKG_DEPENDS}
Maintainer: Gideon Laurie <coder2h2@://github.com>
Description: ${PKG_DESC}
EOT

  for hook in postinst prerm postrm; do
    if [ -f "$pkg_dir/$hook" ]; then
      cp "$pkg_dir/$hook" "$STAGE/DEBIAN/$hook"
      chmod 755 "$STAGE/DEBIAN/$hook"
    fi
  done

  DEB_FILE="$OUT_DIR/${PKG_NAME}_${PKG_VERSION}_${PKG_ARCH}.deb"
  dpkg-deb --root-owner-group --build "$STAGE" "$DEB_FILE"
  rm -rf "$STAGE"
  echo "Built: $DEB_FILE"
done
