-- Hyprland default apps

-- Edit these in Nexus (SUPER + Z -> Shortcuts & apps) or in ~/.config/hypr/settings.json
TERMINAL     = S("apps.terminal",    "kitty")
FILE_MANAGER = S("apps.fileManager", "thunar")
BROWSER      = S("apps.browser",     "firefox")
EDITOR       = S("apps.editor",      "gnome-text-editor --new-window")
CALCULATOR   = S("apps.calculator",  "gnome-calculator")

-- Monitors
MONITOR1 = ""
MONITOR2 = ""
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
NUM_WPM = math.max(1, math.min(10, math.floor(S("workspaces.perMonitor", 3)))) -- Number of workspaces per monitor (Max 10)
