#!/usr/bin/env bash

declare -A layouts
SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

while IFS= read -r event; do
    case "$event" in
        activelayout\>\>*)
            class=$(hyprctl -j activewindow | jq -r '.class // empty')
            idx=$(hyprctl -j devices | jq -r '[.keyboards[] | select(.main == true)][0].active_layout_index // empty')
            [[ -n "$class" && "$idx" =~ ^[0-9]+$ ]] && layouts["$class"]="$idx"
            ;;
        activewindow\>\>*)
            class="${event#*>>}"
            class="${class%%,*}"
            if [[ -n "${layouts[$class]+yes}" ]]; then
                hyprctl switchxkblayout current "${layouts[$class]}" >/dev/null
            fi
            ;;
    esac
done < <(socat -U - "UNIX-CONNECT:$SOCKET")
