#!/usr/bin/env bash
# Open the terminal. If the focused window is VS Code, start it in that window's folder.
# usage: terminal-here.sh <terminal command...>   (VSCODE_CWD=0 disables the VS Code lookup)
dir=""
if [ "${VSCODE_CWD:-1}" != "0" ]; then
  dir=$(hyprctl activewindow -j 2>/dev/null | python3 -c '
import json, os, sys
from urllib.parse import urlparse, unquote
try:
    w = json.load(sys.stdin)
except Exception:
    sys.exit()
cls = (w.get("class") or "").lower()
if cls not in ("com.microsoft.vscode", "code", "code-oss", "vscodium", "cursor"):
    sys.exit()
home = os.path.expanduser("~")
app = {"cursor": "Cursor", "vscodium": "VSCodium", "code-oss": "Code - OSS"}.get(cls, "Code")
try:
    s = json.load(open(f"{home}/.config/{app}/User/globalStorage/storage.json"))
except Exception:
    sys.exit()
ws = s.get("windowsState", {})
last = ws.get("lastActiveWindow") or {}
cands = [last] + (ws.get("openedWindows") or [])
uris = [c.get("folder") for c in cands if c.get("folder")]
uris += [f.get("folderUri") for f in s.get("backupWorkspaces", {}).get("folders", [])]
uris += list(s.get("profileAssociations", {}).get("workspaces", {}))
paths = []
for u in uris:
    if u and u.startswith("file://"):
        p = unquote(urlparse(u).path)
        if os.path.isdir(p) and p not in paths:
            paths.append(p)
# the window title is "[file - ]folder - Visual Studio Code": match the folder name
parts = [x.strip() for x in (w.get("title") or "").split(" - ")[:-1]]
for part in reversed(parts):
    for p in paths:
        if os.path.basename(p) == part:
            print(p); sys.exit()
# no match in the title (e.g. a single window): fall back to the last active folder
for c in (last,):
    u = c.get("folder")
    if u and u.startswith("file://"):
        p = unquote(urlparse(u).path)
        if os.path.isdir(p):
            print(p)
')
fi
[ -n "$dir" ] && cd "$dir"
exec uwsm app -- "$@"
