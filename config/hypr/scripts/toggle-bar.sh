#!/bin/sh
# Toggle the Caelestia side bar between always shown and auto-hide
# (when hidden it still slides out when the mouse touches the screen edge).
f="$HOME/.config/caelestia/shell.json"
tmp="$(mktemp)"
jq --indent 4 '.bar.persistent = (.bar.persistent == false)' "$f" > "$tmp" && cat "$tmp" > "$f"
rm -f "$tmp"
