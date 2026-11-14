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

-- Screen duplication (Nexus -> Displays & system): output "to" shows a copy of "from".
-- The copy leaves the layout, so the pointer cannot wander off onto it.
local MIRROR_FROM = S("mirror.from", "")
local MIRROR_TO   = S("mirror.to", "")
local mirrored    = false

local function rule(m)
    local r = {
        output   = m.output,
        mode     = m.mode or "preferred",
        position = m.position or "auto",
        scale    = tostring(m.scale or 1),
    }
    if MIRROR_FROM ~= "" and m.output == MIRROR_TO and MIRROR_FROM ~= MIRROR_TO then
        r.mirror = MIRROR_FROM
        mirrored = true
    end
    hl.monitor(r)
end

for _, m in ipairs(S("monitors", {})) do
    if type(m) == "table" and m.output and m.output ~= "" then
        rule(m)
    end
end

if not mirrored and MIRROR_TO ~= "" then
    rule({ output = MIRROR_TO })
end
