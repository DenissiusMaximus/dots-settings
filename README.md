# dotfiles

Налаштування CachyOS + Hyprland.

## Що всередині

| Що | Чим |
|---|---|
| Дистрибутив | CachyOS |
| Композитор | Hyprland (конфіг на Lua, `config/hypr/`) |
| Оболонка (панель, лаунчер, сповіщення, локскрін) | [Caelestia Shell](https://github.com/caelestia-dots/shell) на Quickshell |
| Екран входу | greetd + [caelestia-greeter](https://github.com/maylton/caelestia-greeter) |
| Термінал / shell | kitty, fish |
| Файловий менеджер | Thunar |
| Браузер | Firefox |
| Теми | GTK 3/4, Qt5/6 (qt5ct, qt6ct), btop, cava, Spotify (spicetify), Zed |

## Встановлення на новій системі

1. Встановити CachyOS (варіант з Hyprland).
2. Склонувати репозиторій і запустити інсталятор:

   ```sh
   git clone https://github.com/DenissiusMaximus/dots-settings.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

   Скрипт:
   - оновлює систему і ставить пакети з `packages/repo.txt` (ті, яких уже нема в репозиторіях, пропускає);
   - ставить AUR-пакети з `packages/aur.txt` через `paru`;
   - копіює `config/` у `~/.config`, `home/` у `~`, `etc/` у `/etc` (старі конфіги — у `~/.config-backup/<дата>`);
   - вмикає системні та користувацькі сервіси;
   - змінює shell на той, що в `packages/shell.txt` (fish).
3. Зробити ручні кроки нижче і перезавантажитись.

### Ручні кроки після встановлення

- **Екран входу.** `install.sh` копіює лише `/etc/greetd`, а самі скрипти greeter-а (`/usr/local/bin/caelestia-greeter-*`) — ні. Встановити його:

  ```sh
  git clone https://github.com/maylton/caelestia-greeter.git ~/caelestia-greeter
  cd ~/caelestia-greeter && ./install.sh
  ```

- **Розкладка клавіатури для кожної програми.** Сервіс `app-keyboard-layout.service` запускає `~/.local/bin/app-keyboard-layout.sh`, якого немає в репозиторії. Без цього скрипта сервіс не стартує — скопіювати його вручну зі старої системи.
- **Монітори.** Імена моніторів задаються в `config/hypr/config/variables.lua` (`MONITOR1`, `MONITOR2`, ...), розташування — у `monitors.lua`. Дізнатися імена: `hyprctl monitors`.

## Оновлення репозиторію

Після змін у системі:

```sh
cd ~/dotfiles
./save.sh
git add -A && git commit -m update && git push
```

`save.sh` перезаписує `config/`, `home/`, `etc/` поточними файлами і заново генерує списки пакетів і сервісів. Які саме папки з `~/.config` зберігаються — список `CONFIGS` на початку `save.sh`; щоб додати нову програму, допиши її туди.

## Структура

| Шлях | Що там |
|---|---|
| `config/` | файли з `~/.config` |
| `home/` | файли з `~` (`.zshrc`, `.gitconfig`, ...) |
| `etc/` | системні файли з `/etc` (greetd) |
| `packages/` | списки пакетів (repo, AUR), сервісів і shell |

## Hyprland: яка програма на якому столі

Файл: `config/hypr/config/app_workspaces.lua` (у системі — `~/.config/hypr/config/app_workspaces.lua`).

```lua
local apps = {
    ["[Ss]potify"] = "3",
    ["firefox"]    = "2",
}
```

- Ключ — клас вікна (regex). Дізнатися клас: `hyprctl clients`, поле `class`.
- Кілька програм в одному рядку: `["firefox|librewolf"] = "2"`.
- Значення — стіл: `"1"`, `"2"`, ... або іменований `"name:gaming"`.
- `"3 silent"` — відкрити вікно на столі 3, не перемикаючись на нього.

Після зміни: `hyprctl reload`.

Інше про столи:

- `config/hypr/config/workspaces.lua` — на якому моніторі який стіл.
- `config/hypr/config/windowrules.lua` — решта правил вікон (ігри, плаваючі вікна тощо).

## Hyprland: комбінації клавіш

Файл: `config/hypr/config/binds.lua`. `Super` — клавіша Windows. Цифри прив'язані до фізичних клавіш, тож працюють і в AZERTY.

### Вікна

| Клавіші | Дія |
|---|---|
| `Super + Q` | закрити вікно |
| `Super + Esc` | убити вікно (`hyprctl kill`, клікнути по вікну) |
| `Alt + Space` | плаваюче / в сітці |
| `Super + F` | повний екран |
| `Super + D` | розгорнути (максимізувати) |
| `Super + J` | змінити напрям розділення |
| `Super + ←/→/↑/↓` | фокус на вікно в напрямку |
| `Alt + Tab`, `Super + Tab` | наступне вікно |
| `Super + Shift + ←/→/↑/↓` | перемістити вікно в напрямку |
| `Super + ЛКМ` (тягнути) | перемістити вікно мишею |
| `Super + ПКМ` (тягнути) | змінити розмір мишею |
| `Super + -` / `Super + +` | зменшити / збільшити зум екрана (також `-`/`+` на цифровому блоці) |

### Робочі столи

На кожному моніторі 3 столи (`NUM_WPM` у `variables.lua`).

| Клавіші | Дія |
|---|---|
| `Super + 1..9` | перейти на стіл |
| `Super + Ctrl + 1..3` | перейти на стіл N поточного монітора |
| `Super + Ctrl + →/←` | наступний / попередній стіл |
| `Super + Ctrl + ↓` | перший порожній стіл |
| `Super + коліщатко` | гортати столи |
| `Super + Shift + 1..9` | перенести вікно на стіл |
| `Super + Shift + Ctrl + 1..3` | перенести вікно на стіл N поточного монітора |
| `Super + Shift + Alt + 1..3` | те саме, але лишитися на поточному столі |
| `Super + Shift + Ctrl + →/←` | перенести вікно на наступний / попередній стіл |
| `Super + Shift + Ctrl + коліщатко` | те саме коліщатком |
| `Super + Shift + коліщатко` | перенести вікно на інший монітор |
| `Super + S` | показати / сховати scratchpad (спеціальний стіл) |
| `Super + Shift + S` | відправити вікно в scratchpad / повернути назад |
| `Super + Ctrl + S` | перенести вікно на стіл 1 |

### Програми

| Клавіші | Дія |
|---|---|
| `Super + Enter` | термінал (kitty) |
| `Super + E` | файловий менеджер (thunar) |
| `Super + W` | браузер (firefox) |
| `Super + T` | текстовий редактор (gnome-text-editor) |
| `Super + C`, `Calculator` | калькулятор |
| `Ctrl + Shift + Esc` | btop (диспетчер задач) |
| `Super + Space` | лаунчер програм |
| `Super + X` | дашборд |
| `Super + Z` | Caelestia nexus |
| `Super + A` | бічна панель (сповіщення) |
| `Super + V` | історія буфера обміну |
| `Super + .` | емодзі |
| `Super + L` | заблокувати екран |
| `Super + Alt + C` | меню сеансу (вимкнути, перезавантажити...) |

### Утиліти

| Клавіші | Дія |
|---|---|
| `Print` | скріншот |
| `Super + Print` | скріншот із замороженим екраном |
| `Super + P` | піпетка кольору (hyprpicker) |
| `Super + Shift + W` | випадкові шпалери |

### Медіа-клавіші

Гучність, мікрофон, play/pause/next/prev і яскравість працюють через відповідні кнопки клавіатури, навіть на заблокованому екрані.
