-- Remember floating/tiled mode and floating size + position per app (window class).
--
-- Mode:  any float/tile toggle (SUPER + H, mouse, gestures, ...) is saved and applied
--        to every new window of that app, also after a restart.
--        State file: ~/.local/state/hypr/float_memory.lua  ({ [class] = floating })
-- Size / position: of floating windows, saved per app (every few seconds, on close
--        and on shutdown) and applied when the app opens a floating window again
--        (not to its file dialogs). Position is relative to the monitor and clamped
--        to stay on screen. State file: ~/.local/state/hypr/window_sizes.lua
--        ({ [class] = { w, h, x, y } })
--
-- Settings (settings.json / Nexus): windows.rememberFloat, windows.rememberSize,
-- windows.rememberPosition
-- To forget an app, delete its line from the state file (or use Nexus) and reload.

local stateDir  = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr"
local floatFile = stateDir .. "/float_memory.lua"
local sizeFile  = stateDir .. "/window_sizes.lua"

local autoFloat    = S("windows.rememberFloat", true)
local rememberSize = S("windows.rememberSize", true)
local rememberPos  = S("windows.rememberPosition", true)

-- Windows that must stay floating no matter what the app's choice is
local pipPattern = "^([Pp]icture[-%s]?[Ii]n[-%s]?[Pp]icture)"
local pipTitle   = "negative:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"

local function load(file)
    local ok, t = pcall(dofile, file)
    if ok and type(t) == "table" then return t end
    return {}
end

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    return keys
end

local function writeFile(file, text)
    os.execute("mkdir -p '" .. stateDir .. "'")
    local f = io.open(file, "w")
    if not f then return end
    f:write(text)
    f:close()
end

local function escape(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%{%}%|\\]", "\\%0"))
end

local function isPip(win)
    return (win.title or ""):match(pipPattern) or (win.initial_title or ""):match(pipPattern)
end

---------------------------------------------------------------------------
-- Floating / tiled mode
---------------------------------------------------------------------------

local floatMemory = load(floatFile)
local floatRules  = {}

local function saveFloat()
    local out = { "return {\n" }
    for _, k in ipairs(sortedKeys(floatMemory)) do
        out[#out + 1] = string.format("    [%q] = %s,\n", k, tostring(floatMemory[k]))
    end
    out[#out + 1] = "}\n"
    writeFile(floatFile, table.concat(out))
end

local function applyFloatRule(class, float)
    if floatRules[class] then floatRules[class]:set_enabled(false) end
    floatRules[class] = hl.window_rule({
        match = { class = "^(" .. escape(class) .. ")$", title = pipTitle },
        float = float,
    })
end

for class, float in pairs(floatMemory) do
    if type(float) == "boolean" then applyFloatRule(class, float) end
end

local function rememberFloat(win, float)
    local class = win and win.class
    if not class or class == "" or isPip(win) then return end
    if floatMemory[class] == float then return end
    floatMemory[class] = float
    saveFloat()
    applyFloatRule(class, float)
end

-- SUPER + H: toggle and remember (works even with windows.rememberFloat = false)
local function toggleAndRemember()
    local win = hl.get_active_window()
    if not win then return end
    local float = not win.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    rememberFloat(win, float)
end

(BIND or hl.bind)("SUPER + H", toggleAndRemember)

-- Any other float/tile toggle (mouse, gestures, other binds). Window rules applied
-- when a window opens don't fire this event, only real state changes do.
if autoFloat then
    hl.on("window.update_state", function(win, changes)
        if win and win.mapped and changes and changes.float ~= nil then
            rememberFloat(win, changes.float)
        end
    end)
end

---------------------------------------------------------------------------
-- Floating size and position
---------------------------------------------------------------------------

if not rememberSize and not rememberPos then return end

-- { [class] = { w, h, x, y } }   x, y: position relative to the window's monitor
local sizes     = load(sizeFile)
local sizeRules = {}
local dirty     = false

-- Dialogs keep their own size (their titles, see the modal rules in windowrules.lua)
local notDialog = "negative:^(Open|Open File|Save As|Choose Files|Authentication Required|"
    .. "Confirm to replace files|File Operation Progress|File Upload.*|.*[Dd]ialog.*)$"

local function saveSizes()
    if not dirty then return end
    dirty = false
    local out = { "return {\n" }
    for _, class in ipairs(sortedKeys(sizes)) do
        local s = sizes[class]
        if s[3] and s[4] then
            out[#out + 1] = string.format("    [%q] = { %d, %d, %d, %d },\n", class, s[1], s[2], s[3], s[4])
        else
            out[#out + 1] = string.format("    [%q] = { %d, %d },\n", class, s[1], s[2])
        end
    end
    out[#out + 1] = "}\n"
    writeFile(sizeFile, table.concat(out))
end

local function applySizeRule(class, s)
    if sizeRules[class] then sizeRules[class]:set_enabled(false) end
    local rule = {
        match = {
            class         = "^(" .. escape(class) .. ")$",
            initial_title = notDialog,
            title         = pipTitle,
        },
    }
    if rememberSize then rule.size = { s[1], s[2] } end
    if rememberPos and s[3] and s[4] then
        -- Clamped, so the window stays on screen (other monitor / lower resolution)
        rule.move = {
            string.format("max(0, min(%d, monitor_w - window_w))", s[3]),
            string.format("max(0, min(%d, monitor_h - window_h))", s[4]),
        }
    end
    if rule.size or rule.move then sizeRules[class] = hl.window_rule(rule) end
end

for class, s in pairs(sizes) do
    if type(s) == "table" and tonumber(s[1]) and tonumber(s[2]) then
        applySizeRule(class, s)
    else
        sizes[class] = nil
    end
end

local function vec(v)
    if type(v) ~= "table" then return nil end
    local x, y = v.x or v[1], v.y or v[2]
    if not x or not y then return nil end
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function usable(win)
    return win and win.mapped and win.floating and (win.fullscreen or 0) == 0
        and not isPip(win) and win.class and win.class ~= ""
end

-- { w, h, x, y } of a window, x/y relative to its monitor
local function geometry(win)
    local w, h = vec(win.size)
    local x, y = vec(win.at)
    if not w or not x then return nil end
    local m = win.monitor
    if m then x, y = x - (m.x or 0), y - (m.y or 0) end
    return { w, h, x, y }
end

local function store(class, g)
    if g[1] < 50 or g[2] < 50 then return end
    local old = sizes[class]
    if old and old[1] == g[1] and old[2] == g[2] and old[3] == g[3] and old[4] == g[4] then return end
    sizes[class] = g
    dirty = true
    applySizeRule(class, g)
end

-- Periodic snapshot: if an app has several floating windows, keep the largest
-- (the main window, not its small popups)
local function recordAll()
    local best = {}
    for _, win in ipairs(hl.get_windows({ floating = true, mapped = true }) or {}) do
        if usable(win) then
            local g = geometry(win)
            local b = best[win.class]
            if g and (not b or g[1] * g[2] > b[1] * b[2]) then best[win.class] = g end
        end
    end
    for class, g in pairs(best) do store(class, g) end
    saveSizes()
end

hl.on("window.close", function(win)
    pcall(function()
        if not usable(win) then return end
        -- Only the app's last floating window counts (closing a popup must not shrink it)
        for _, other in ipairs(hl.get_windows({ class = "^(" .. escape(win.class) .. ")$", floating = true, mapped = true }) or {}) do
            if other.address ~= win.address then return end
        end
        local g = geometry(win)
        if g then store(win.class, g) end
    end)
    saveSizes()
end)
hl.on("hyprland.shutdown", recordAll)
hl.on("config.unload", recordAll)

-- Reboot/logout may kill apps without close events, so also save periodically
hl.timer(function() pcall(recordAll) end, { timeout = 5000, type = "repeat" })
