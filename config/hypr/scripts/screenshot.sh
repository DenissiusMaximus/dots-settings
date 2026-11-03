#!/usr/bin/env bash
# Screenshot of the focused monitor -> clipboard + notification.
# Clicking the notification opens the screenshot in swappy (editor).
mon="$1"
dir="${XDG_CACHE_HOME:-$HOME/.cache}/screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d%H%M%S).png"

grim ${mon:+-o "$mon"} "$file" || exit 1
wl-copy < "$file"

action=$(notify-send -a screenshot -i image-x-generic-symbolic \
    -h "STRING:image-path:$file" \
    --action=open=Open \
    "Screenshot taken" "Copied to clipboard. Click to edit.")

[ "$action" = open ] && setsid swappy -f "$file" >/dev/null 2>&1 &
