-- Look and feel configuration
-- Values with S(...) are edited in Nexus (SUPER + Z -> Windows & look) / settings.json

hl.config({
    general = {
        gaps_in = S("general.gapsIn", 2),
        gaps_out = S("general.gapsOut", 4),
        border_size = S("general.borderSize", 1),
        extend_border_grab_area = 10,
        resize_on_border = S("general.resizeOnBorder", true),
        col = {
            active_border = {
                colors = { CACHYLGREEN, CACHYDGREEN },
                angle = 45,
            },
            inactive_border = CACHYGRAY,
        },
    },
    group = {
        col = {
            border_active = CACHYLBLUE,
            border_inactive = CACHYGRAY,
            border_locked_active = CACHYDBLUE,
            border_locked_inactive = CACHYGRAY,
        },
        groupbar = {
            col = {
                active = CACHYLGREEN,
                inactive = CACHYGRAY,
                locked_active = CACHYDBLUE,
                locked_inactive = CACHYGRAY,
            },
        },
    },
    decoration = {
        dim_special = S("decoration.dimSpecial", 0.3),
        rounding = S("decoration.rounding", 10),
        active_opacity = S("decoration.activeOpacity", 0.95),
        inactive_opacity = S("decoration.inactiveOpacity", 0.85),
        fullscreen_opacity = 1,
        blur = {
            enabled = S("decoration.blur.enabled", true),
            size = S("decoration.blur.size", 5),
            passes = S("decoration.blur.passes", 4),
            special = true,
        },
    },
})
