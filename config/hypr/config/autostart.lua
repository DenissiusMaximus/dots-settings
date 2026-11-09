-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart
-- Names are shown in Nexus (SUPER + Z -> Shortcuts & apps -> Autostart); keep one entry per line.
-- Commands added in Nexus are in extra_autostart.lua / settings.json.

local AUTOSTART = {
    { name = "Pass session environment to apps", cmd = "dbus-update-activation-environment --systemd --all" },
    { name = "Desktop shell (Caelestia or Noctalia, chosen in Nexus)", cmd = "~/.config/hypr/scripts/shell-ctl.sh start" },
    { name = "Workspace overview (SUPER + Tab)", cmd = "qs -c overview -d" },
    { name = "Clipboard history", cmd = "wl-paste --watch cliphist store" },
    { name = "Allow root apps on the screen", cmd = "xhost +SI:localuser:root" },
}

-- Changes made in Nexus: settings.json "autostartOverrides", keyed by name:
--   { "enabled": false } or { "cmd": "..." }
local OVERRIDES = S("autostartOverrides", {})

hl.on("hyprland.start", function ()
    for _, a in ipairs(AUTOSTART) do
        local o = OVERRIDES[a.name]
        local cmd = a.cmd
        if type(o) == "table" and type(o.cmd) == "string" and o.cmd ~= "" then cmd = o.cmd end
        if not (type(o) == "table" and o.enabled == false) then
            hl.exec_cmd(cmd)
        end
    end
end)
