#!/bin/sh
# Desktop shell selector: Caelestia or Noctalia (setting "shell" in ~/.config/hypr/settings.json).
#   shell-ctl.sh start            start the selected shell (Hyprland autostart)
#   shell-ctl.sh switch <name>    save the choice, stop the other shell, start this one
#   shell-ctl.sh hypr-settings    open the Hyprland settings (Nexus; the lite one while Noctalia runs)
#   shell-ctl.sh get              print the selected shell
# While Noctalia is active, Caelestia is not running; its Hyprland pages (keys, keyboard layouts,
# windows, displays) are then shown by the small "nexus-lite" quickshell config.
CONF="$HOME/.config/hypr/settings.json"
LITE="$HOME/.config/quickshell/nexus-lite"

selected() {
    s=$(jq -r '.shell // "caelestia"' "$CONF" 2>/dev/null)
    [ "$s" = noctalia ] && echo noctalia || echo caelestia
}

stop_caelestia() { caelestia shell -k >/dev/null 2>&1; }
stop_noctalia()  { qs -c nexus-lite kill >/dev/null 2>&1; pkill -x noctalia; }

start_caelestia() {
    caelestia shell -d >/dev/null 2>&1
    # Noctalia rewrites the themes of terminals, GTK, btop...: restore the Caelestia scheme
    set -- $(caelestia scheme get 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk '/^ *(Name|Flavour|Mode|Variant):/ {print $2}')
    [ $# -eq 4 ] && caelestia scheme set -n "$1" -f "$2" -m "$3" -v "$4" >/dev/null 2>&1
}

start_noctalia() {
    "$LITE/build.sh"
    setsid noctalia -d >/dev/null 2>&1
    setsid qs -c nexus-lite -d >/dev/null 2>&1
}

case "$1" in
    start)
        if [ "$(selected)" = noctalia ]; then start_noctalia; else caelestia shell -d >/dev/null 2>&1; fi
        ;;
    switch)
        [ "$2" = noctalia ] || [ "$2" = caelestia ] || exit 1
        [ "$(selected)" = "$2" ] && exit 0
        tmp=$(mktemp)
        jq --indent 2 --arg s "$2" '.shell = $s' "$CONF" > "$tmp" && cat "$tmp" > "$CONF"
        rm -f "$tmp"
        hyprctl reload >/dev/null 2>&1 # binds depend on the shell
        if [ "$2" = noctalia ]; then
            stop_caelestia; sleep 1; start_noctalia
        else
            stop_noctalia; sleep 1; start_caelestia
        fi
        ;;
    hypr-settings)
        if [ "$(selected)" = noctalia ]; then qs -c nexus-lite ipc call nexus open; else caelestia shell nexus open; fi
        ;;
    get) selected ;;
    *) echo "usage: $0 start|switch <caelestia|noctalia>|hypr-settings|get" >&2; exit 1 ;;
esac
