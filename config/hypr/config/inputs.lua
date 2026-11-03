-- Values with S(...) are edited in Nexus (SUPER + Z -> Input) / settings.json
hl.config({
    input = {
        kb_layout = S("input.kbLayout", "us,ua"),
        kb_options = S("input.kbOptions", "grp:alt_shift_toggle"),
        sensitivity = S("input.sensitivity", -0.5),
        touchpad = {
            natural_scroll = S("input.naturalScroll", true),
        },
    },
})

if S("input.gestures", true) then
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = "close" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left", action = "float" })
end
