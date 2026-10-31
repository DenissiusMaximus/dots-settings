hl.config({
    input = {
        kb_layout = "us,ua",
        kb_options = "grp:alt_shift_toggle",
	sensitivity = -0.5,	
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = "close" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left", action = "float" })
