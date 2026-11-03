-- Extra autostart commands added in Nexus (SUPER + Z -> Shortcuts & apps -> Autostart),
-- stored in ~/.config/hypr/settings.json ("autostart"). Built-in ones are in autostart.lua.
hl.on("hyprland.start", function ()
    for _, cmd in ipairs(S("autostart", {})) do
        if type(cmd) == "string" and cmd ~= "" then
            hl.exec_cmd(cmd)
        end
    end
end)
