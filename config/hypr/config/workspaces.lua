-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- The number of workspaces per monitor is NUM_WPM (variables.lua, set from Nexus).
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR, default = true })
for i = 1, NUM_WPM do
    hl.workspace_rule({ workspace = tostring(i), monitor = MONITOR1, default = true, persistent = true })
end
-- hl.workspace_rule({ workspace = "4", monitor = MONITOR2, default = true, persistent = true })

-- For other layouts such as scrolling, see example below
-- hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, layout = "scrolling" })
