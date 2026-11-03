-- Extra shortcuts added in Nexus (SUPER + Z -> Shortcuts & apps -> Custom shortcuts),
-- stored in ~/.config/hypr/settings.json ("binds"): { "keys": "SUPER + B", "command": "..." }.
-- The built-in shortcuts are in binds.lua.
for _, b in ipairs(S("binds", {})) do
    if type(b) == "table" and b.keys and b.keys ~= "" and b.command and b.command ~= "" then
        local ok, err = pcall(hl.bind, b.keys, hl.dsp.exec_cmd(b.command))
        if not ok then print("custom bind '" .. b.keys .. "' failed: " .. tostring(err)) end
    end
end
