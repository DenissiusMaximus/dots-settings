pragma Singleton

import QtQuick
import Caelestia.I18n

// Trimmed copy of the caelestia PageRegistry: only the local Hyprland pages.
QtObject {
    id: root

    readonly property list<var> pages: [
        {
            label: Tr.tr("Windows & look"),
            icon: "select_window",
            description: Tr.tr("Gaps, borders, opacity, blur, animations"),
            category: "hyprland"
        },
        {
            label: Tr.tr("Workspaces"),
            icon: "workspaces",
            description: Tr.tr("Workspaces, app rules, overview"),
            category: "hyprland"
        },
        {
            label: Tr.tr("Input"),
            icon: "keyboard",
            description: Tr.tr("Keyboard layouts, mouse, touchpad"),
            category: "hyprland"
        },
        {
            label: Tr.tr("Displays & system"),
            icon: "monitor",
            description: Tr.tr("Resolution, scale, refresh rate, desktop shell"),
            category: "hyprland"
        },
        {
            label: Tr.tr("Shortcuts & apps"),
            icon: "keyboard_command_key",
            description: Tr.tr("Default apps, custom shortcuts, autostart"),
            category: "hyprland"
        }
    ]
}
