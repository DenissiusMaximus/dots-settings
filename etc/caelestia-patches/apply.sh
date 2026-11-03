#!/bin/sh
# Applies local patches to caelestia-shell (/etc/xdg/quickshell/caelestia).
# Run automatically by /etc/pacman.d/hooks/caelestia-patches.hook after every
# install/upgrade of caelestia-shell, and once by ~/dotfiles/install.sh.
# Safe to run any time: already-applied patches are skipped, and patches that no
# longer apply (e.g. fixed upstream) are skipped with a message instead of failing.
DIR="$(dirname "$(readlink -f "$0")")"
TARGET=/etc/xdg/quickshell/caelestia
[ -d "$TARGET" ] || exit 0

# New files (e.g. the Hyprland pages in Nexus) are copied as-is from overlay/
if [ -d "$DIR/overlay" ]; then
    cp -r "$DIR/overlay/." "$TARGET/" && echo "caelestia-patches: copied overlay files"
fi

for p in "$DIR"/*.patch; do
    [ -e "$p" ] || continue
    name="$(basename "$p")"
    # `patch` exits 0 even when it skips hunks, so look at its output instead
    out="$(LC_ALL=C patch -d "$TARGET" -p1 -N --dry-run < "$p" 2>&1)"
    if [ $? -eq 0 ] && ! printf '%s' "$out" | grep -qE 'ignored|Skipping|FAILED|Reversed'; then
        patch -d "$TARGET" -p1 -N -s --no-backup-if-mismatch < "$p" && echo "caelestia-patches: applied $name"
    elif printf '%s' "$out" | grep -q 'Reversed (or previously applied)' && ! printf '%s' "$out" | grep -q 'FAILED'; then
        echo "caelestia-patches: $name already applied"
    else
        echo "caelestia-patches: $name does not apply (maybe fixed upstream), skipped"
    fi
done
echo "caelestia-patches: restart the shell to see changes: caelestia shell -k; caelestia shell -d"
exit 0
