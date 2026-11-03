-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart
-- Names are shown in Nexus (SUPER + Z -> Shortcuts & apps -> Autostart); keep one entry per line.
-- Commands added in Nexus are in extra_autostart.lua / settings.json.

local AUTOSTART = {
    { name = "Pass session environment to apps", cmd = "dbus-update-activation-environment --systemd --all" },
    { name = "Caelestia shell (bar, launcher, notifications)", cmd = "caelestia shell -d" },
    { name = "Workspace overview (SUPER + Tab)", cmd = "qs -c overview -d" },
    { name = "Clipboard history", cmd = "wl-paste --watch cliphist store" },
    { name = "Allow root apps on the screen", cmd = "xhost +SI:localuser:root" },
}

hl.on("hyprland.start", function ()
    for _, a in ipairs(AUTOSTART) do
        hl.exec_cmd(a.cmd)
    end
end)
