#!/bin/sh
# Applies local patches to caelestia-shell (/etc/xdg/quickshell/caelestia).
# Run automatically by /etc/pacman.d/hooks/caelestia-patches.hook after every
# install/upgrade of caelestia-shell, and once by ~/dotfiles/install.sh.
# Safe to run any time: already-applied patches are skipped, and patches that no
# longer apply (e.g. fixed upstream) are skipped with a message instead of failing.
DIR="$(dirname "$(readlink -f "$0")")"
TARGET=/etc/xdg/quickshell/caelestia
[ -d "$TARGET" ] || exit 0

for p in "$DIR"/*.patch; do
    [ -e "$p" ] || continue
    name="$(basename "$p")"
    if patch -d "$TARGET" -p1 -R --dry-run -s -t < "$p" >/dev/null 2>&1; then
        echo "caelestia-patches: $name already applied"
    elif patch -d "$TARGET" -p1 -N --dry-run -s -t < "$p" >/dev/null 2>&1; then
        patch -d "$TARGET" -p1 -N -s -t --no-backup-if-mismatch < "$p" && echo "caelestia-patches: applied $name"
    else
        echo "caelestia-patches: $name does not apply (maybe fixed upstream), skipped"
    fi
done
echo "caelestia-patches: restart the shell to see changes: caelestia shell -k; caelestia shell -d"
exit 0
