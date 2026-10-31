-- Which app opens on which workspace.
-- Format: ["window class"] = "workspace"
-- Find the class with: hyprctl clients  (the "class" field)
-- The class is a regex, e.g. "[Ss]potify" or "firefox|librewolf".
-- Workspace: "1", "2", ... or "name:gaming".
-- Append " silent" to the workspace ("3 silent") to open the window there without switching focus to it.

local apps = {
    ["[Ss]potify"] = "3",
    -- ["firefox"]    = "2",
    -- ["kitty"]      = "1",
}

for class, workspace in pairs(apps) do
    hl.window_rule({ match = { class = "^(" .. class .. ")$" }, workspace = workspace })
end
