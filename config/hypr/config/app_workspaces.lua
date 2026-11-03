-- Which app opens on which workspace.
-- Edit in Nexus (SUPER + Z -> Workspaces -> App workspaces) or in
-- ~/.config/hypr/settings.json ("appWorkspaces").
-- class:     window class regex, e.g. "[Ss]potify" or "firefox|librewolf"
--            (find it with: hyprctl clients, the "class" field)
-- workspace: "1", "2", ... or "name:gaming"
-- silent:    open the window there without switching focus to it

for _, rule in ipairs(S("appWorkspaces", {})) do
    if type(rule) == "table" and rule.class and rule.class ~= "" and rule.workspace and tostring(rule.workspace) ~= "" then
        local ws = tostring(rule.workspace) .. (rule.silent and " silent" or "")
        hl.window_rule({ match = { class = "^(" .. rule.class .. ")$" }, workspace = ws })
    end
end
