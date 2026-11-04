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

Коротко — встановити CachyOS (варіант з Hyprland) і виконати:

```sh
# 1. Конфіги, пакети, сервіси
sudo pacman -S --needed git
git clone https://github.com/DenissiusMaximus/dots-settings.git ~/dotfiles
cd ~/dotfiles
./install.sh

# 2. Екран входу (caelestia-greeter)
git clone https://github.com/maylton/caelestia-greeter.git ~/caelestia-greeter
cd ~/caelestia-greeter
./install.sh

# 3. Залежності скрипта розкладки клавіатури
sudo pacman -S --needed jq socat

# 4. Перезавантаження
reboot
```

Детальніше:

1. Встановити CachyOS (варіант з Hyprland).
2. Склонувати репозиторій і запустити `./install.sh` (крок 1 вище). Його можна запускати й на вже налаштованій системі: він ставить лише те, чого бракує, і не падає, якщо все вже є. Скрипт:
   - оновлює систему і ставить відсутні пакети з `packages/repo.txt` (ті, яких уже нема в репозиторіях, пропускає);
   - ставить відсутні AUR-пакети з `packages/aur.txt` через `paru`;
   - копіює `config/` у `~/.config`, `home/` у `~`, `etc/` у `/etc`: відсутні файли додає, однакові пропускає, змінені замінює (старі версії — у `~/.config-backup/<дата>`), зайвих файлів не чіпає;
   - застосовує патчі до caelestia-shell з `etc/caelestia-patches/` (далі їх після кожного оновлення `caelestia-shell` сам застосовує pacman-хук `etc/pacman.d/hooks/caelestia-patches.hook`);
   - вмикає системні та користувацькі сервіси;
   - змінює shell на той, що в `packages/shell.txt` (fish).
3. Встановити екран входу (крок 2 вище). `install.sh` копіює лише `/etc/greetd`, а самі скрипти greeter-а (`/usr/local/bin/caelestia-greeter-*`) ставить його власний інсталятор.
4. Розкладка клавіатури запам'ятовується окремо для кожної програми: сервіс `app-keyboard-layout.service` запускає `~/.local/bin/app-keyboard-layout.sh` (лежить у `home/.local/bin/`). Йому потрібні `jq` і `socat` (крок 3 вище).
5. **Монітори.** Імена моніторів задаються в `config/hypr/config/variables.lua` (`MONITOR1`, `MONITOR2`, ...), розташування — у `monitors.lua`. Дізнатися імена: `hyprctl monitors`.

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
| `etc/` | системні файли з `/etc` (greetd, патчі caelestia і pacman-хук до них) |
| `packages/` | списки пакетів (repo, AUR), сервісів і shell |

## Налаштування Hyprland у Nexus (`Super + Z`)

У Nexus (вікно налаштувань Caelestia) є окрема група сторінок для Hyprland:

| Сторінка | Що там |
|---|---|
| Windows & look | відступи, рамки, заокруглення, прозорість, розмиття, анімації, запам'ятовування плаваючого режиму (будь-яке перемикання, не лише `Super + H`) і розміру плаваючих вікон — також після перезавантаження; список запам'ятованих програм |
| Workspaces | кількість столів на монітор, яка програма на якому столі, огляд (`Super + Tab`) |
| Input | розкладки, клавіші перемикання, чутливість миші, тачпад і жести, розкладка окремо для кожної програми |
| Displays & system | роздільність, частота і масштаб кожного монітора, VRR, поглинання вікон терміналом, вставка середньою кнопкою |
| Shortcuts & apps | програми для `Super + Enter/E/W/T/C`; усі комбінації клавіш (вбудовані можна перепризначити, вимкнути чи скинути, свої — додати й видалити); автозапуск так само |

Як це працює:

- Значення зберігаються в `config/hypr/settings.json` (у системі `~/.config/hypr/settings.json`). Lua-конфіги читають їх через `S("ключ", типове_значення)`, а сам файл завантажує `config/hypr/config/settings.lua`. Після кожної зміни Nexus виконує `hyprctl reload`. Файл можна редагувати й вручну.
- Вбудовані комбінації та автозапуск лишаються в `binds.lua` / `autostart.lua` (назви — таблиці `DESC` і `AUTOSTART`), а зміни з Nexus зберігаються окремо: `bindOverrides` і `autostartOverrides` у `settings.json`.
- Огляд пише у свій `config/quickshell/overview/config.json` і після змін перезапускається.
- Самі сторінки лежать в `etc/caelestia-patches/overlay/` (`apply.sh` копіює їх у `/etc/xdg/quickshell/caelestia`), а в меню Nexus їх додає патч `caelestia-nexus-hyprland-pages.patch`. Обидва застосовуються автоматично після кожного оновлення `caelestia-shell`.

## Hyprland: яка програма на якому столі

Найпростіше — у Nexus: `Super + Z` → Workspaces → App workspaces. Правила зберігаються в `config/hypr/settings.json` (у системі — `~/.config/hypr/settings.json`), застосовує їх `config/hypr/config/app_workspaces.lua`:

```json
"appWorkspaces": [
  { "class": "[Ss]potify", "workspace": "3", "silent": false }
]
```

- `class` — клас вікна (regex). Дізнатися клас: `hyprctl clients`, поле `class`. Кілька програм в одному правилі: `"firefox|librewolf"`.
- `workspace` — стіл: `"1"`, `"2"`, ... або іменований `"name:gaming"`.
- `silent: true` — відкрити вікно на цьому столі, не перемикаючись на нього.

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
| `Super + H` | плаваюче / в сітці (запам'ятовується для програми) |
| `Super + F` | повний екран |
| `Super + D` | розгорнути (максимізувати) |
| `Super + J` | змінити напрям розділення |
| `Super + ←/→/↑/↓` | фокус на вікно в напрямку (і підняти його наверх) |
| `Alt + Tab` | наступне вікно (і підняти його наверх) |
| `Super + Tab` | огляд усіх столів (quickshell-overview, `config/quickshell/overview/`) |
| `Super + Shift + ←/→/↑/↓` | перемістити вікно в напрямку |
| `Super + ЛКМ` (тягнути) | перемістити вікно мишею |
| `Super + ПКМ` (тягнути) | змінити розмір мишею |
| `Super + Alt + →/←` | ширше / вужче (крок 40 px, можна затиснути) |
| `Super + Alt + ↓/↑` | вище / нижче (крок 40 px, можна затиснути) |
| `Super + -` / `Super + +` | зменшити / збільшити зум екрана (також `-`/`+` на цифровому блоці) |

### Робочі столи

На кожному моніторі 3 столи (змінюється в Nexus → Workspaces або `workspaces.perMonitor` у `settings.json`).

| Клавіші | Дія |
|---|---|
| `Super + 1..9` | перейти на стіл (у режимі scratchpad — на scratchpad N) |
| `Super + Ctrl + 1..3` | перейти на стіл N поточного монітора |
| `Super + Ctrl + →/←` | наступний / попередній стіл |
| `Super + Ctrl + ↓` | перший порожній стіл |
| `Super + коліщатко` | гортати столи |
| `Super + Shift + 1..9` | перенести вікно на стіл (у режимі scratchpad — у scratchpad N) |
| `Super + Shift + Ctrl + 1..3` | перенести вікно на стіл N поточного монітора |
| `Super + Shift + Alt + 1..3` | те саме, але лишитися на поточному столі |
| `Super + Shift + Ctrl + →/←` | перенести вікно на наступний / попередній стіл |
| `Super + Shift + Ctrl + коліщатко` | те саме коліщатком |
| `Super + Shift + коліщатко` | перенести вікно на інший монітор |
| `Super + S` | сховати відкритий scratchpad / відкрити останній використаний |
| `Super + Shift + S` | відправити вікно в scratchpad / повернути назад |
| `Super + Alt + 1..9` | показати / сховати scratchpad N (1 — головний) |
| `Super + Ctrl + Alt + 1..9` | відправити вікно в scratchpad N / повернути назад |
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
| `Print` | скріншот екрана в буфер + сповіщення (клік — редактор swappy) |
| `Super + Print` | те саме для виділеної області |
| `Super + P` | піпетка кольору (hyprpicker) |
| `Super + Shift + W` | випадкові шпалери |

### Медіа-клавіші

Гучність, мікрофон, play/pause/next/prev і яскравість працюють через відповідні кнопки клавіатури, навіть на заблокованому екрані.
