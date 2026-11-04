-- Remember floating/tiled mode and floating size per app (window class).
--
-- Mode:  any float/tile toggle (SUPER + H, mouse, gestures, ...) is saved and applied
--        to every new window of that app, also after a restart.
--        State file: ~/.local/state/hypr/float_memory.lua  ({ [class] = floating })
-- Size:  the size of floating windows is saved per app (every few seconds, on close
--        and on shutdown) and applied when the app opens a floating window again
--        (not to its file dialogs). State file: ~/.local/state/hypr/window_sizes.lua
--
-- Settings (settings.json / Nexus): windows.rememberFloat, windows.rememberSize
-- To forget an app, delete its line from the state file (or use Nexus) and reload.

local stateDir  = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr"
local floatFile = stateDir .. "/float_memory.lua"
local sizeFile  = stateDir .. "/window_sizes.lua"

local autoFloat    = S("windows.rememberFloat", true)
local rememberSize = S("windows.rememberSize", true)

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
-- Floating size
---------------------------------------------------------------------------

if not rememberSize then return end

-- { [class] = { w, h } }
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
        out[#out + 1] = string.format("    [%q] = { %d, %d },\n", class, s[1], s[2])
    end
    out[#out + 1] = "}\n"
    writeFile(sizeFile, table.concat(out))
end

local function applySizeRule(class, s)
    if sizeRules[class] then sizeRules[class]:set_enabled(false) end
    sizeRules[class] = hl.window_rule({
        match = {
            class         = "^(" .. escape(class) .. ")$",
            initial_title = notDialog,
            title         = pipTitle,
        },
        size = { s[1], s[2] },
    })
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

local function store(class, w, h)
    if w < 50 or h < 50 then return end
    local old = sizes[class]
    if old and old[1] == w and old[2] == h then return end
    sizes[class] = { w, h }
    dirty = true
    applySizeRule(class, sizes[class])
end

-- Periodic snapshot: if an app has several floating windows, keep the largest
-- (the main window, not its small popups)
local function recordAll()
    local best = {}
    for _, win in ipairs(hl.get_windows({ floating = true, mapped = true }) or {}) do
        if usable(win) then
            local w, h = vec(win.size)
            local b = best[win.class]
            if w and (not b or w * h > b[1] * b[2]) then best[win.class] = { w, h } end
        end
    end
    for class, s in pairs(best) do store(class, s[1], s[2]) end
    saveSizes()
end

hl.on("window.close", function(win)
    pcall(function()
        if not usable(win) then return end
        -- Only the app's last floating window counts (closing a popup must not shrink it)
        for _, other in ipairs(hl.get_windows({ class = "^(" .. escape(win.class) .. ")$", floating = true, mapped = true }) or {}) do
            if other.address ~= win.address then return end
        end
        local w, h = vec(win.size)
        if w then store(win.class, w, h) end
    end)
    saveSizes()
end)
hl.on("hyprland.shutdown", recordAll)
hl.on("config.unload", recordAll)

-- Reboot/logout may kill apps without close events, so also save periodically
hl.timer(function() pcall(recordAll) end, { timeout = 5000, type = "repeat" })
