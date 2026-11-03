#!/usr/bin/env bash
# Відновлює налаштування на CachyOS.
# Можна запускати і на свіжій, і на вже налаштованій системі: ставить лише те,
# чого бракує, однакові файли пропускає, а змінені замінює, зберігаючи старі
# версії в ~/.config-backup/<дата>.
set -euo pipefail
cd "$(dirname "$0")"

BACKUP="$HOME/.config-backup/$(date +%F_%H%M%S)"

echo "==> Оновлення системи"
sudo pacman -Syu --noconfirm

echo "==> Пакети з репозиторіїв"
command -v paru  >/dev/null || sudo pacman -S --needed --noconfirm paru
command -v rsync >/dev/null || sudo pacman -S --needed --noconfirm rsync
# лише ті, що є в репо і ще не встановлені
missing="$(comm -12 <(sort -u packages/repo.txt) <(pacman -Slq | sort -u) \
    | comm -23 - <(pacman -Qq | sort -u))"
if [ -n "$missing" ]; then
    echo "$missing" | sudo pacman -S --needed --noconfirm - || echo "   (деякі пакети не встановились, пропускаю)"
else
    echo "   усе вже встановлено"
fi

echo "==> Пакети з AUR"
if [ -s packages/aur.txt ]; then
    missing="$(comm -23 <(sort -u packages/aur.txt) <(pacman -Qq | sort -u))"
    if [ -n "$missing" ]; then
        echo "$missing" | paru -S --needed --noconfirm - || echo "   (деякі AUR-пакети не встановились, пропускаю)"
    else
        echo "   усе вже встановлено"
    fi
fi

# Копіює вміст $1 у $2: додає відсутні файли, однакові пропускає, змінені
# замінює (стара версія — у $3). Зайві файли в $2 не чіпає.
sync_dir() {
    local src="$1" dst="$2" bak="$3" sudo="${4:-}" own=()
    # системні файли мають належати root, а не власнику репозиторію
    [ -n "$sudo" ] && own=(--no-owner --no-group)
    $sudo mkdir -p "$dst"
    $sudo rsync -a "${own[@]}" --checksum --backup --backup-dir="$bak" "$src/" "$dst/"
}

echo "==> Конфіги (змінені файли збережено в $BACKUP)"
sync_dir config "$HOME/.config" "$BACKUP/config"
sync_dir home   "$HOME"         "$BACKUP/home"
[ -d etc ] && sync_dir etc /etc "$BACKUP/etc" sudo

echo "==> Патчі caelestia (далі pacman-хук застосовує їх сам після оновлень)"
[ -x /etc/caelestia-patches/apply.sh ] && sudo /etc/caelestia-patches/apply.sh || true

echo "==> Сервіси"
while read -r s; do [ -n "$s" ] && sudo systemctl enable "$s" 2>/dev/null || true; done < packages/services.txt
while read -r s; do [ -n "$s" ] && systemctl --user enable "$s" 2>/dev/null || true; done < packages/user-services.txt

SH="$(cat packages/shell.txt 2>/dev/null || true)"
if [ -n "$SH" ] && command -v "$SH" >/dev/null && [ "$(basename "$SHELL")" != "$SH" ]; then
    chsh -s "$(command -v "$SH")" || echo "   (не вдалося змінити shell, пропускаю)"
fi

echo "==> Готово! Перезавантаж комп'ютер."
