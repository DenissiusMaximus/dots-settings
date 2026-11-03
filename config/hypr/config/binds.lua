local mainMod = "SUPER"
local shellCall = "caelestia shell "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

-- AZERTY fix: the number-row keys emit symbols (& é " ' ...) without Shift, so
-- binding to the digit characters fails. Bind by physical keycode instead.
-- Digit d -> evdev keycode: 1..9 => 10..18, 0 => 19
local function digitCode(d)
    return "code:" .. (d == 0 and 19 or (9 + d))
end

-- Readable names of the shortcuts, shown in Nexus (SUPER + Z -> Shortcuts & apps).
-- Key: the combination with digit keys written as N. Shortcuts without a name
-- here still work, they are just listed with their technical keys.
local DESC = {
    ["SUPER + H"]                                = "Float / tile window (remembered per app)",
    ["SUPER + Escape"]                        = "Kill a window (click it)",
    ["SUPER + Q"]                             = "Close window",
    ["SUPER + D"]                             = "Maximise window",
    ["SUPER + F"]                             = "Fullscreen",
    ["SUPER + J"]                             = "Switch split: side by side / one above the other",
    ["SUPER + Left"]                          = "Focus window to the left",
    ["SUPER + Right"]                         = "Focus window to the right",
    ["SUPER + Up"]                            = "Focus window above",
    ["SUPER + Down"]                          = "Focus window below",
    ["ALT + Tab"]                             = "Next window",
    ["SUPER + Tab"]                           = "Workspace overview",
    ["SUPER + SHIFT + Up"]                    = "Move window up",
    ["SUPER + SHIFT + Right"]                 = "Move window right",
    ["SUPER + SHIFT + Left"]                  = "Move window left",
    ["SUPER + SHIFT + Down"]                  = "Move window down",
    ["SUPER + SHIFT + mouse_up"]              = "Move window to the previous monitor",
    ["SUPER + SHIFT + mouse_down"]            = "Move window to the next monitor",
    ["SUPER + CONTROL + SHIFT + Right"]       = "Move window to the next workspace",
    ["SUPER + CONTROL + SHIFT + Left"]        = "Move window to the previous workspace",
    ["SUPER + CONTROL + SHIFT + mouse_up"]    = "Move window to the previous workspace (scroll)",
    ["SUPER + CONTROL + SHIFT + mouse_down"]  = "Move window to the next workspace (scroll)",
    ["SUPER + SHIFT + CONTROL + N"]           = "Move window to workspace N of this monitor",
    ["SUPER + SHIFT + ALT + N"]               = "Move window to workspace N of this monitor, stay here",
    ["SUPER + mouse:272"]                     = "Drag window with the mouse",
    ["SUPER + mouse:273"]                     = "Resize window with the mouse",
    ["SUPER + ALT + Right"]                   = "Make window wider",
    ["SUPER + ALT + Left"]                    = "Make window narrower",
    ["SUPER + ALT + Down"]                    = "Make window taller",
    ["SUPER + ALT + Up"]                      = "Make window shorter",
    ["SUPER + Minus"]                         = "Zoom out",
    ["SUPER + Plus"]                          = "Zoom in",
    ["SUPER + code:82"]                       = "Zoom out (keypad)",
    ["SUPER + code:86"]                       = "Zoom in (keypad)",
    ["SUPER + Return"]                        = "Terminal",
    ["SUPER + E"]                             = "File manager",
    ["SUPER + T"]                             = "Text editor",
    ["SUPER + C"]                             = "Calculator",
    ["XF86Calculator"]                        = "Calculator (calculator key)",
    ["SUPER + W"]                             = "Browser",
    ["CONTROL + SHIFT + Escape"]              = "Task manager (btop)",
    ["SUPER + Z"]                             = "Settings (Nexus)",
    ["SUPER + X"]                             = "Dashboard",
    ["SUPER + Space"]                         = "App launcher",
    ["SUPER + period"]                        = "Emoji picker",
    ["SUPER + L"]                             = "Lock screen",
    ["SUPER + ALT + C"]                       = "Session menu (power off, reboot...)",
    ["XF86AudioRaiseVolume"]                  = "Volume up",
    ["XF86AudioLowerVolume"]                  = "Volume down",
    ["XF86AudioMute"]                         = "Mute sound",
    ["XF86AudioMicMute"]                      = "Mute microphone",
    ["XF86AudioPlay"]                         = "Play / pause",
    ["XF86AudioPause"]                        = "Play / pause",
    ["XF86AudioNext"]                         = "Next track",
    ["XF86AudioPrev"]                         = "Previous track",
    ["XF86MonBrightnessUp"]                   = "Brightness up",
    ["XF86MonBrightnessDown"]                 = "Brightness down",
    ["SUPER + P"]                             = "Colour picker",
    ["Print"]                                 = "Screenshot of the screen",
    ["SUPER + Print"]                         = "Screenshot of a region",
    ["SUPER + SHIFT + W"]                     = "Random wallpaper",
    ["SUPER + V"]                             = "Clipboard history",
    ["SUPER + A"]                             = "Notifications sidebar",
    ["SUPER + CONTROL + N"]                   = "Go to workspace N of this monitor",
    ["SUPER + CONTROL + Right"]               = "Next workspace",
    ["SUPER + CONTROL + Left"]                = "Previous workspace",
    ["SUPER + CONTROL + Down"]                = "First empty workspace",
    ["SUPER + mouse_down"]                    = "Previous workspace (scroll)",
    ["SUPER + mouse_up"]                      = "Next workspace (scroll)",
    ["SUPER + CONTROL + mouse_up"]            = "Previous workspace (scroll)",
    ["SUPER + CONTROL + mouse_down"]          = "Next workspace (scroll)",
    ["SUPER + SHIFT + S"]                     = "Send window to the scratchpad / bring it back",
    ["SUPER + S"]                             = "Show / hide the last scratchpad",
    ["SUPER + N"]                             = "Go to workspace N (scratchpad N when one is open)",
    ["SUPER + SHIFT + N"]                     = "Move window to workspace N (scratchpad N when one is open)",
    ["SUPER + ALT + N"]                       = "Show / hide scratchpad N",
    ["SUPER + CONTROL + ALT + N"]             = "Send window to scratchpad N / bring it back",
    ["SUPER + CONTROL + S"]                   = "Move window to workspace 1",
}

-- hl.bind with the description from DESC added and the changes made in Nexus
-- applied. Overrides live in settings.json, "bindOverrides", keyed by the
-- original combination as written in DESC:
--   "SUPER + Q": { "keys": "SUPER + K" }   -> moved to SUPER + K
--   "SUPER + Q": { "enabled": false }      -> turned off
--   "SUPER + N": { "keys": "SUPER + ALT" } -> number series: only the modifiers change
local OVERRIDES = S("bindOverrides", {})

local function bind(keys, action, opts)
    local norm = keys:gsub("code:1[0-9]", "N")
    local id = DESC[keys] and keys or (DESC[norm] and norm or nil)
    if id then
        local o = OVERRIDES[id]
        if type(o) == "table" then
            if o.enabled == false then return end
            if type(o.keys) == "string" and o.keys ~= "" then
                if id ~= keys then
                    keys = o.keys .. " + " .. keys:match("(code:1[0-9])$")
                else
                    keys = o.keys
                end
            end
        end
        opts = opts or {}
        if not opts.description then opts.description = DESC[id] end
    end
    local ok, err
    if opts then ok, err = pcall(hl.bind, keys, action, opts) else ok, err = pcall(hl.bind, keys, action) end
    if not ok then print("bind '" .. keys .. "' failed: " .. tostring(err)) end
end
BIND = bind -- used by float_memory.lua (SUPER + H)

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
bind(mainMod .. " + Q",           hl.dsp.window.close())
-- SUPER + H (toggle float + remember per app) is defined in config/float_memory.lua
bind(mainMod .. " + D",           hl.dsp.window.fullscreen({ mode = 1 }))
bind(mainMod .. " + F",           hl.dsp.window.fullscreen())
bind(mainMod .. " + J",           hl.dsp.layout("togglesplit"))

-- Change focus (and raise the focused floating window on top)
local function focusRaise(dsp)
    return function()
        hl.dispatch(dsp)
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end
bind(mainMod .. " + Left",  focusRaise(hl.dsp.focus({ direction = "left" })))
bind(mainMod .. " + Right", focusRaise(hl.dsp.focus({ direction = "right" })))
bind(mainMod .. " + Up",    focusRaise(hl.dsp.focus({ direction = "up" })))
bind(mainMod .. " + Down",  focusRaise(hl.dsp.focus({ direction = "down" })))
bind("ALT + Tab",           focusRaise(hl.dsp.window.cycle_next()))
bind(mainMod .. " + Tab",   hl.dsp.exec_cmd("qs ipc -c overview call overview toggle")) -- workspace overview

-- Move active window around workspaces & monitors
bind(mainMod .. " + SHIFT + Up",                   hl.dsp.window.move({ direction = "u" }))
bind(mainMod .. " + SHIFT + Right",                hl.dsp.window.move({ direction = "r" }))
bind(mainMod .. " + SHIFT + Left",                 hl.dsp.window.move({ direction = "l" }))
bind(mainMod .. " + SHIFT + Down",                 hl.dsp.window.move({ direction = "d" }))
-- SUPER + SHIFT + <n>: see "Special workspaces" below (scratchpad-aware)
bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "-1" }))
bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "+1" }))
bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "m+1" }))
bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "m-1" }))
bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "m-1" }))
bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "m+1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    bind(mainMod .. " + SHIFT + CONTROL + " .. digitCode(key), hl.dsp.window.move({ workspace = "m~" .. i }))
end
for i = 1, NUM_WPM do
    local key = i % 10
    bind(mainMod .. " + SHIFT + ALT + " .. digitCode(key), hl.dsp.window.move({ workspace = "m~" .. i, follow = false }))
end

-- Move & Resize with mouse
bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Resize active window with keyboard (works for tiled and floating windows)
local resizeStep = 40
bind(mainMod .. " + ALT + Right", hl.dsp.window.resize({ x =  resizeStep, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + Left",  hl.dsp.window.resize({ x = -resizeStep, y = 0, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + Down",  hl.dsp.window.resize({ x = 0, y =  resizeStep, relative = true }), { repeating = true })
bind(mainMod .. " + ALT + Up",    hl.dsp.window.resize({ x = 0, y = -resizeStep, relative = true }), { repeating = true })

-- Zoom
local function zoomfunction(value)
    local zoomvalue = hl.get_config("cursor:zoom_factor")
    if (zoomvalue + value) > 3.0 then
        hl.config({ cursor = { zoom_factor = 3.0 } })
    elseif (zoomvalue + value) < 1.0 then
        hl.config({ cursor = { zoom_factor = 1.0 } })
    else
        hl.config({ cursor = { zoom_factor = zoomvalue + value } })
    end
end
bind(mainMod .. " + Minus", function() zoomfunction(-0.3) end, { repeating = true})
bind(mainMod .. " + Plus", function() zoomfunction(0.3) end, { repeating = true })

--# Zoom with keypad
bind(mainMod .. " + code:82", function() zoomfunction(-0.3) end, { repeating = true })
bind(mainMod .. " + code:86", function() zoomfunction(0.3) end, { repeating = true })


------------------
---- LAUNCHER ----
------------------

bind(mainMod .. " + Return",     hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
bind(mainMod .. " + E",          hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
bind(mainMod .. " + T",          hl.dsp.exec_cmd(launchPrefix .. EDITOR))
bind(mainMod .. " + C",          hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
bind("XF86Calculator",           hl.dsp.exec_cmd(launchPrefix .. CALCULATOR))
bind(mainMod .. " + W",          hl.dsp.exec_cmd(launchPrefix .. BROWSER))
bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
bind(mainMod .. " + Z",          hl.dsp.exec_cmd(shellCall .. "nexus open"))
bind(mainMod .. " + X",          hl.dsp.exec_cmd(shellCall .. "drawers toggle dashboard"))
bind(mainMod .. " + Space", hl.dsp.exec_cmd(shellCall .. "drawers toggle launcher"))
bind(mainMod .. " + period",     hl.dsp.exec_cmd("caelestia emoji -p"))
bind(mainMod .. " + L", hl.dsp.exec_cmd(shellCall .. "lock lock"))
bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd(shellCall .. "drawers toggle session"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true })

-- Media
bind("XF86AudioPlay",  hl.dsp.exec_cmd(shellCall .. "mpris playPause"),   { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd(shellCall .. "mpris playPause"),   { locked = true })
bind("XF86AudioNext",  hl.dsp.exec_cmd(shellCall .. "mpris next"),     { locked = true })
bind("XF86AudioPrev",  hl.dsp.exec_cmd(shellCall .. "mpris previous"), { locked = true })

-- Brightness
bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(shellCall .. "brightness set +5%"),   { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(shellCall .. "brightness set 5%-"), { locked = true, repeating = true })

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
-- Screen Capture
bind(mainMod .. " + P",     hl.dsp.exec_cmd("hyprpicker -a -n"))
-- Print: screenshot of the focused monitor -> clipboard + notification (click it to edit in swappy)
bind("Print", function()
    local mon = hl.get_active_monitor()
    hl.exec_cmd("~/.config/hypr/scripts/screenshot.sh '" .. (mon and mon.name or "") .. "'")
end)
-- Super + Print: select a region -> clipboard + notification (click it to edit)
bind(mainMod .. " + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --region"))

-- Theming and Wallpaper
bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("caelestia wallpaper -r"))

-- Clipboard
bind(mainMod .. " + V", hl.dsp.exec_cmd("caelestia clipboard"))

-- Notifications
bind(mainMod .. " + A", hl.dsp.exec_cmd(shellCall .. "drawers toggle sidebar"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on monitors
-- hl.bind(mainMod .. " + " .. digitCode(1), hl.dsp.focus({ monitor = MONITOR1 }))
-- hl.bind(mainMod .. " + " .. digitCode(2), hl.dsp.focus({ monitor = MONITOR2 }))
-- hl.bind(mainMod .. " + " .. digitCode(3), hl.dsp.focus({ monitor = MONITOR3 }))

-- Focus on workspace number
-- Absolute
-- SUPER + <n>: see "Special workspaces" below (scratchpad-aware)
-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    bind(mainMod .. " + CONTROL + " .. digitCode(key), hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Move to adjacent workspaces and next empty on a given monitor
bind(mainMod .. " + CONTROL + Right",       hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + CONTROL + Left",        hl.dsp.focus({ workspace = "m-1" }))
bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m-1" }))
bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))
bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Special workspaces (scratchpads)
-- Scratchpad 1 is the main one ("special"), 2..9 are "special:2".."special:9"
-- (new scratchpads created in the SUPER + Tab overview get the same numbers).
local function scratchpadWorkspace(n)
    return n == 1 and "special" or ("special:" .. n)
end

-- Full workspace name as Hyprland reports it ("special" is reported as "special:special")
local function scratchpadFullName(n)
    return n == 1 and "special:special" or ("special:" .. n)
end

local function openScratchpadName()
    local mon = hl.get_active_monitor()
    return mon and mon.active_special_workspace and mon.active_special_workspace.name or nil
end

-- Show / hide scratchpad n
local function toggleScratchpad(n)
    return function()
        if n == 1 then
            hl.dispatch(hl.dsp.workspace.toggle_special())
        else
            hl.dispatch(hl.dsp.workspace.toggle_special(tostring(n)))
        end
    end
end

-- Send the active window to scratchpad n, or bring it back if it's already there
local function toggleScratchpadWindow(n)
    return function()
        local win = hl.get_active_window()
        if not win or not win.workspace then return end
        local target = scratchpadWorkspace(n)
        local inSpecial = win.workspace.name:find("^special") ~= nil
        if win.workspace.name == target or (n == 1 and inSpecial) then
            local mon = hl.get_active_monitor()
            if not mon or not mon.active_workspace then return end
            hl.dispatch(hl.dsp.window.move({ workspace = tostring(mon.active_workspace.id) }))
            mon = hl.get_active_monitor()
            if mon and mon.active_special_workspace and mon.active_special_workspace.is_empty then
                hl.dispatch(toggleScratchpad(n))
            end
        else
            hl.dispatch(hl.dsp.window.move({ workspace = target }))
        end
    end
end

bind(mainMod .. " + SHIFT + S", toggleScratchpadWindow(1))
-- Toggle a scratchpad by its full name ("special:special", "special:2", ...)
local function toggleScratchpadByName(name)
    if name == "special:special" then
        hl.dispatch(hl.dsp.workspace.toggle_special())
    else
        hl.dispatch(hl.dsp.workspace.toggle_special((name:gsub("^special:", ""))))
    end
end

-- Remember the last scratchpad that was open (however it was opened)
local lastScratchpad = "special:special"
hl.on("workspace.special_active", function()
    local open = openScratchpadName()
    if open then lastScratchpad = open end
end)

-- SUPER + S: hide whichever scratchpad is open, otherwise reopen the last used one
bind(mainMod .. " + S", function()
    toggleScratchpadByName(openScratchpadName() or lastScratchpad)
end)
-- SUPER + <n> / SUPER + SHIFT + <n>: while a scratchpad is open they work on
-- scratchpads (switch to / send window to scratchpad n), otherwise on normal workspaces.
for i = 1, 9 do
    bind(mainMod .. " + " .. digitCode(i), function()
        local open = openScratchpadName()
        if not open then
            hl.dispatch(hl.dsp.focus({ workspace = i }))
        elseif open ~= scratchpadFullName(i) then
            hl.dispatch(toggleScratchpad(i))
        end
    end)
    bind(mainMod .. " + SHIFT + " .. digitCode(i), function()
        if openScratchpadName() then
            hl.dispatch(hl.dsp.window.move({ workspace = scratchpadWorkspace(i), follow = false }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = i }))
        end
    end)
    bind(mainMod .. " + ALT + " .. digitCode(i),             toggleScratchpad(i))
    bind(mainMod .. " + CONTROL + ALT + " .. digitCode(i),   toggleScratchpadWindow(i))
end
bind(mainMod .. " + CONTROL + S", hl.dsp.window.move({ workspace = 1 }))
