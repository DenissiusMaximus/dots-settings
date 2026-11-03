-- Monitor wiki https://wiki.hypr.land/Configuring/Basics/Monitors/
-- Per-monitor resolution / scale are set in Nexus (SUPER + Z -> Displays & system)
-- and stored in ~/.config/hypr/settings.json ("monitors").

-- Fallback for every monitor without its own rule
hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = "1",
})

for _, m in ipairs(S("monitors", {})) do
    if type(m) == "table" and m.output and m.output ~= "" then
        hl.monitor({
            output   = m.output,
            mode     = m.mode or "preferred",
            position = m.position or "auto",
            scale    = tostring(m.scale or 1),
        })
    end
end
