#!/usr/bin/env bash
# Відновлює налаштування на свіжій CachyOS.
set -euo pipefail
cd "$(dirname "$0")"

echo "==> Оновлення системи"
sudo pacman -Syu --noconfirm

echo "==> Пакети з репозиторіїв"
command -v paru >/dev/null || sudo pacman -S --needed --noconfirm paru
# пропускаємо пакети, яких більше нема в репо
comm -12 <(sort packages/repo.txt) <(pacman -Slq | sort -u) \
    | sudo pacman -S --needed --noconfirm -

echo "==> Пакети з AUR"
[ -s packages/aur.txt ] && paru -S --needed --noconfirm - < packages/aur.txt || true

echo "==> Конфіги (старі збережено в ~/.config-backup)"
BACKUP="$HOME/.config-backup/$(date +%F_%H%M%S)"
mkdir -p "$BACKUP"
for p in config/* config/systemd/user; do
    [ -e "$p" ] || continue
    [ "$p" = config/systemd ] && continue
    rel="${p#config/}"
    if [ -e "$HOME/.config/$rel" ]; then
        mkdir -p "$BACKUP/$(dirname "$rel")"
        mv "$HOME/.config/$rel" "$BACKUP/$rel"
    fi
    mkdir -p "$HOME/.config/$(dirname "$rel")"
    cp -a "$p" "$HOME/.config/$rel"
done
cp -a home/. "$HOME/"
[ -d etc ] && sudo cp -a etc/. /etc/

echo "==> Сервіси"
while read -r s; do sudo systemctl enable "$s" 2>/dev/null || true; done < packages/services.txt
while read -r s; do systemctl --user enable "$s" 2>/dev/null || true; done < packages/user-services.txt

SH="$(cat packages/shell.txt)"
command -v "$SH" >/dev/null && [ "$(basename "$SHELL")" != "$SH" ] && chsh -s "$(command -v "$SH")"

echo "==> Готово! Перезавантаж комп'ютер."
