-- Settings edited from Caelestia Nexus (SUPER + Z -> Hyprland pages).
-- Source of truth: ~/.config/hypr/settings.json. Nexus writes it and runs
-- `hyprctl reload`; the other config files read values through S("a.b.c", default).
-- The file can also be edited by hand. If it is missing or broken, the defaults
-- in each config file are used.

local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/settings.json"

-- Minimal JSON decoder (objects, arrays, strings, numbers, true/false/null)
local function decode(str)
    local pos = 1

    local function ws()
        pos = str:find("[^ \t\r\n]", pos) or (#str + 1)
    end

    local value

    local function parseString()
        pos = pos + 1 -- opening quote
        local out = {}
        while true do
            local c = str:sub(pos, pos)
            if c == "" then error("unterminated string") end
            if c == '"' then pos = pos + 1; break end
            if c == "\\" then
                local n = str:sub(pos + 1, pos + 1)
                local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
                if map[n] then
                    out[#out + 1] = map[n]
                    pos = pos + 2
                elseif n == "u" then
                    local code = tonumber(str:sub(pos + 2, pos + 5), 16) or 63
                    out[#out + 1] = utf8 and utf8.char(code) or "?"
                    pos = pos + 6
                else
                    error("bad escape")
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end
        return table.concat(out)
    end

    function value()
        ws()
        local c = str:sub(pos, pos)
        if c == "{" then
            pos = pos + 1
            local t = {}
            ws()
            if str:sub(pos, pos) == "}" then pos = pos + 1; return t end
            while true do
                ws()
                local k = parseString()
                ws()
                if str:sub(pos, pos) ~= ":" then error("expected ':'") end
                pos = pos + 1
                t[k] = value()
                ws()
                local d = str:sub(pos, pos)
                pos = pos + 1
                if d == "}" then return t end
                if d ~= "," then error("expected ',' or '}'") end
            end
        elseif c == "[" then
            pos = pos + 1
            local t = {}
            ws()
            if str:sub(pos, pos) == "]" then pos = pos + 1; return t end
            while true do
                t[#t + 1] = value()
                ws()
                local d = str:sub(pos, pos)
                pos = pos + 1
                if d == "]" then return t end
                if d ~= "," then error("expected ',' or ']'") end
            end
        elseif c == '"' then
            return parseString()
        elseif str:sub(pos, pos + 3) == "true" then
            pos = pos + 4; return true
        elseif str:sub(pos, pos + 4) == "false" then
            pos = pos + 5; return false
        elseif str:sub(pos, pos + 3) == "null" then
            pos = pos + 4; return nil
        else
            local num = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
            if not num or num == "" then error("unexpected '" .. c .. "' at " .. pos) end
            pos = pos + #num
            return tonumber(num)
        end
    end

    return value()
end

SETTINGS = {}
do
    local f = io.open(path, "r")
    if f then
        local text = f:read("a")
        f:close()
        local ok, res = pcall(decode, text)
        if ok and type(res) == "table" then
            SETTINGS = res
        else
            print("hypr settings.json: parse error, using defaults: " .. tostring(res))
        end
    end
end

-- S("decoration.blur.size", 5) -> value from settings.json or the default
function S(key, default)
    local v = SETTINGS
    for part in key:gmatch("[^.]+") do
        if type(v) ~= "table" then return default end
        v = v[part]
    end
    if v == nil then return default end
    return v
end
