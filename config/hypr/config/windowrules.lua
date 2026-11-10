-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/
hl.window_rule({
    match = {},
    float = true,
})
-- Generic floating position
hl.window_rule({ match = { float = true }, persistent_size = true })

-- Picture-in-Picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    size              = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin               = true,
})

-- Gaming
local gamingApps = "^(steam_app.*|gamescope)$"
local gamingWorkspace = "name:gaming"

hl.window_rule({ match = { content = "game" }, workspace = gamingWorkspace })
hl.window_rule({ match = { xdg_tag = "^(.*game.*)$" }, workspace = gamingWorkspace, fullscreen_state = 2, content = "game", sync_fullscreen = true })
hl.window_rule({ match = { class = gamingApps }, workspace = gamingWorkspace })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Friends List)$" }, float = true })
hl.window_rule({ match = { class = "^(steam)$", title = "^(Launching\\.{3})$" }, float = true, center = true, workspace = gamingWorkspace })
hl.window_rule({
    match = {
        class         = gamingApps,
        title         = "^(.+)$",
        initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    content          = "game",
    decorate         = false,
    fullscreen_state = 2,
    size             = { "monitor_w", "monitor_h" },
    sync_fullscreen  = true,
})
hl.window_rule({
    match = {
        class         = "^(steam_app.*)$",
        initial_title = "^$",
    },
    center           = true,
    float            = true,
    fullscreen       = false,
    fullscreen_state = 0,
    workspace        = gamingWorkspace,
})

-- Apps
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, monitor = PRIMARY_MONITOR, center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, float = true, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" } })
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.kde\\.ark)$" }, size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" } })
hl.window_rule({
    match = {
        class = "^([Tt]hunar)$",
        title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
    },
    float = true,
    size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
    move = {
        "max(20, min(cursor_x - (window_w*0.50), monitor_w - window_w + 20))", -- X axis clamping
        "max(20, min(cursor_y - 50, monitor_h - window_h + 20))" -- Y axis clamping
    },
})

-- REAPER: the main window is tiled, everything else (menus, dialogs, ReaFruit) floats
hl.window_rule({
    match = { class = "^(REAPER)$", title = "^(REAPER v.*|\\[.*\\] - REAPER.*|.* - REAPER v.*)$" },
    tile  = true,
})
hl.window_rule({
    match = { class = "^(REAPER)$", title = "negative:^(REAPER v.*|\\[.*\\] - REAPER.*|.* - REAPER v.*)$" },
    float = true,
})
-- REAPER: popup menus open at the cursor, dialogs/settings/error windows stay centred
hl.window_rule({
    match = { class = "^(REAPER)$", title = "^(menu)$" },
    float = true,
    move  = {
        "max(5, min(cursor_x, monitor_w - window_w - 5))",
        "max(5, min(cursor_y, monitor_h - window_h - 5))",
    },
})
hl.window_rule({
    match = { class = "^(REAPER)$", title = "negative:^(REAPER v.*|\\[.*\\] - REAPER.*|.* - REAPER v.*|menu|ReaFruit.*|)$" },
    float  = true,
    center = true,
})
-- REAPER tooltips are untitled windows: REAPER places them itself, so no centring (it showed them in
-- the middle of the screen first), no animation, no focus steal, no decoration
hl.window_rule({
    match = { class = "^(REAPER)$", title = "^$" },
    float = true,
    no_anim = true,
    no_focus = true,
    no_initial_focus = true,
    no_shadow = true,
    no_blur = true,
    border_size = 0,
    rounding = 0,
})

-- ReaFruit piano roll: floating, resizable. Resize it with the grip in the bottom-right
-- corner of the roll: ReaFruit (ReaImGui) then resizes the native window itself. Do NOT pin the
-- size here: a native window smaller than the roll's ImGui window cuts its content off, and
-- resizing the native window from outside (Hyprland) is not picked up by the roll.
-- Min size = what ReaFruit itself needs (1329x760); the max only keeps the window on the screen.
hl.window_rule({
    match    = { class = "^(REAPER)$", title = "^(ReaFruit.*)$" },
    float    = true,
    -- no `center`: ReaFruit decides where its window is from its own saved position; if Hyprland
    -- puts it somewhere else the roll's hit-testing (which note is under the mouse) is offset by the difference
    min_size = { "1329", "760" }, -- ReaFruit's own minimum (toolbar); below it the roll and the window drift apart and the mouse is read offset
    max_size = { "monitor_w - 20", "monitor_h - 20" },
})

-- Opacity Overrides
local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

hl.window_rule({ match = { class = "^(firefox|zen|REAPER)$" }, opacity = "1.0 override" })
hl.window_rule({ match = { class = terminals }, opacity = "1.0 override" }) -- Override opacity in favor of terminal settings for opacity. If your terminal doesn't support transparency, you can remove this rule.
hl.window_rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Float Utility Windows
local floatApps = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}
for _, m in ipairs(floatApps) do hl.window_rule({ match = m, float = true }) end

-- Remembered per-app float/tile choice (overrides the rules above, not the modals below)
require("config.float_memory")

-- Float Common Modals
local modalMatches = {
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$"},
}
for _, m in ipairs(modalMatches) do hl.window_rule({ match = m, float = true }) end

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
