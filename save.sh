#!/usr/bin/env bash
# Зберігає поточні налаштування системи в цей репозиторій.
set -euo pipefail
cd "$(dirname "$0")"

CONFIGS=(hypr caelestia fish kitty alacritty fuzzel gtk-3.0 gtk-4.0 qt5ct qt6ct qtengine
         btop cava micro uwsm xsettingsd noctalia Thunar shelly swash zed spicetify
         quickshell/overview systemd/user kdeglobals mimeapps.list user-dirs.dirs user-dirs.locale)
HOME_FILES=(.zshrc .bashrc .bash_profile .gitconfig .icons .local/bin/app-keyboard-layout.sh)
ETC_FILES=(greetd)

rm -rf config home etc
mkdir -p config home etc packages

for c in "${CONFIGS[@]}"; do
    [ -e "$HOME/.config/$c" ] || continue
    mkdir -p "config/$(dirname "$c")"
    cp -a "$HOME/.config/$c" "config/$c"
done
find config -name '*.bak' -delete

for f in "${HOME_FILES[@]}"; do
    [ -e "$HOME/$f" ] || continue
    mkdir -p "home/$(dirname "$f")"
    cp -a "$HOME/$f" "home/$f"
done

for f in "${ETC_FILES[@]}"; do
    [ -r "/etc/$f" ] && cp -a "/etc/$f" "etc/$f" 2>/dev/null || true
done

pacman -Qqen > packages/repo.txt
pacman -Qqem > packages/aur.txt
systemctl list-unit-files --state=enabled --no-legend | awk '{print $1}' \
    | grep -v '@' > packages/services.txt
systemctl --user list-unit-files --state=enabled --no-legend | awk '{print $1}' > packages/user-services.txt
basename "$(getent passwd "$USER" | cut -d: -f7)" > packages/shell.txt

echo "Збережено. Не забудь: git add -A && git commit -m update && git push"
