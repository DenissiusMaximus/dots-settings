#!/usr/bin/env bash
# Screenshot -> clipboard + notification. Clicking the notification opens it in swappy.
#   screenshot.sh <monitor>   - whole monitor
#   screenshot.sh --region    - select a region with slurp
dir="${XDG_CACHE_HOME:-$HOME/.cache}/screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d%H%M%S).png"

if [ "$1" = --region ]; then
    geom=$(slurp -d) || exit 0   # Esc cancels
    grim -g "$geom" "$file" || exit 1
else
    grim ${1:+-o "$1"} "$file" || exit 1
fi
wl-copy < "$file"

action=$(notify-send -a screenshot -i image-x-generic-symbolic \
    -h "STRING:image-path:$file" \
    --action=open=Open \
    "Screenshot taken" "Copied to clipboard. Click to edit.")

[ "$action" = open ] && setsid swappy -f "$file" >/dev/null 2>&1 &
