#!/bin/bash
# Update a single AUR package: pkgver -> checksums -> .SRCINFO -> build -> namcap
# Usage: update_pkg.sh <pkgdir> <newver>
# Exit codes: 0 = success, 1 = build/namcap failure (caller creates an Issue)
# Runs inside an Arch container (Actions) or on any Arch system; deps must be installed.
set -euo pipefail

PKG="$1"
VER="$2"
cd "$PKG"

# 1. bump pkgver
sed -i "s/^pkgver=.*/pkgver=$VER/" PKGBUILD

# 2. refresh checksums (re-downloads sources; SKIP entries are preserved)
updpkgsums

# 3. regenerate .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 4. build
makepkg -f

# 5. namcap: any E-level finding fails the update
#    -e elfpaths: /opt install layout is legal for Electron/-bin packages (false positive)
if namcap -e elfpaths *.pkg.tar.zst | tee namcap.log | grep -E ' E: '; then
  echo "::error::namcap found E-level errors (see namcap.log)"
  exit 1
fi

echo "OK: $PKG updated to $VER"
