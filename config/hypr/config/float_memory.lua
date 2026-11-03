-- Remember floating/tiled mode per app (window class).
-- Toggle with SUPER + H: the choice is saved and applied to every new window
-- of that app (also after restart). State file: ~/.local/state/hypr/float_memory.lua
-- To forget an app, delete its line from that file and reload Hyprland.

local stateDir  = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr"
local stateFile = stateDir .. "/float_memory.lua"

-- Windows that must stay floating no matter what the app's choice is
local pipTitle = "negative:^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$"

local function load()
    local ok, t = pcall(dofile, stateFile)
    if ok and type(t) == "table" then return t end
    return {}
end

local function save(t)
    os.execute("mkdir -p '" .. stateDir .. "'")
    local f = io.open(stateFile, "w")
    if not f then return end
    f:write("return {\n")
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    for _, k in ipairs(keys) do
        f:write(string.format("    [%q] = %s,\n", k, tostring(t[k])))
    end
    f:write("}\n")
    f:close()
end

local function escape(s)
    return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%{%}%|\\]", "\\%0"))
end

local memory = load()
local rules  = {}

local function applyRule(class, float)
    if rules[class] then rules[class]:set_enabled(false) end
    rules[class] = hl.window_rule({
        match = { class = "^(" .. escape(class) .. ")$", title = pipTitle },
        float = float,
    })
end

for class, float in pairs(memory) do applyRule(class, float) end

local function toggleAndRemember()
    local win = hl.get_active_window()
    if not win then return end
    local float = not win.floating
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    local class = win.class
    if class and class ~= "" then
        memory[class] = float
        save(memory)
        applyRule(class, float)
    end
end

hl.bind("SUPER + H", toggleAndRemember)
