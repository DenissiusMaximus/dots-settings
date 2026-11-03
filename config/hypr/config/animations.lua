-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

-- Default beziers
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("overshoot",      { type = "bezier", points = { {0.5, 0.9}, {0.1, 1.1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 500, dampening = 35 })
hl.curve("rubber",         { type = "spring", mass = 1, stiffness = 200,  dampening = 15 })

-- Animations (on/off and speed are edited in Nexus: SUPER + Z -> Windows & look)
local animOn = S("animations.enabled", true)
local animScale = S("animations.speed", 1) -- >1 = slower, <1 = faster
local function sp(v) return math.max(0.1, v * animScale) end
hl.config({ animations = { enabled = animOn } })
hl.animation({ leaf = "global",              enabled = true, speed = sp(3), bezier = "quick"                 })
hl.animation({ leaf = "windows",             enabled = true, speed = sp(3), spring = "easy",  style = "slide" })
hl.animation({ leaf = "workspaces",          enabled = true, speed = sp(5), bezier = "quick", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = sp(2), bezier = "quick", style = "slide top"})
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = sp(2), bezier = "quick", style = "slide bottom"})
