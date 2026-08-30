#!/bin/bash
# Push a single package directory to its AUR repo.
# Usage: push_aur.sh <pkgdir> <aur-repo-name>
# Requires GIT_SSH_COMMAND configured with the AUR SSH key (done by the workflow).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG="$1"
NAME="$2"
VER=$(grep '^pkgver=' "$REPO_ROOT/$PKG/PKGBUILD" | cut -d= -f2)

rm -rf /tmp/aur-push
git clone "ssh://aur@aur.archlinux.org/$NAME.git" /tmp/aur-push
cd /tmp/aur-push
git config user.name "alex3236"
git config user.email "me@alex3236.moe"
cp "$REPO_ROOT/$PKG/PKGBUILD" "$REPO_ROOT/$PKG/.SRCINFO" .
git add -A
if git diff --cached --quiet; then
  echo "no changes to push for $NAME"
  exit 0
fi
git commit -m "Update to $VER"
git push
echo "pushed $NAME $VER"
