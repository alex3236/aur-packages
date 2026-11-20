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
# copy every file the package directory tracks, not just PKGBUILD/.SRCINFO:
# local sources live there too (e.g. gety-bin's gety-license.txt) and a stale
# copy makes the AUR package fail its integrity check
mapfile -t files < <(git -C "$REPO_ROOT" ls-files "$PKG")
for file in "${files[@]}"; do
  cp "$REPO_ROOT/$file" "${file#"$PKG"/}"
done
git add -A
if git diff --cached --quiet; then
  echo "no changes to push for $NAME"
  exit 0
fi
git commit -m "$NAME $VER: update"
git push
echo "pushed $NAME $VER"
