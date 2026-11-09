#!/bin/sh
# Builds the "nexus-lite" quickshell config: the Hyprland pages of Nexus only, from the
# installed caelestia-shell (symlinks) + own trimmed page registries. Used while the
# Noctalia shell is active (Caelestia itself is not running then).
# Safe to re-run (e.g. after a caelestia-shell upgrade).
SRC=/etc/xdg/quickshell/caelestia
DIR="$(dirname "$(readlink -f "$0")")"
cd "$DIR" || exit 1
for d in assets components services utils; do ln -sfn "$SRC/$d" "$d"; done
mkdir -p modules/nexus
for f in "$SRC"/modules/*; do
    n=$(basename "$f")
    [ "$n" = nexus ] && continue
    ln -sfn "$f" "modules/$n"
done
for f in "$SRC"/modules/nexus/*; do
    n=$(basename "$f")
    case "$n" in PageRegistry.qml|PageCompRegistry.qml) continue ;; esac
    ln -sfn "$f" "modules/nexus/$n"
done
